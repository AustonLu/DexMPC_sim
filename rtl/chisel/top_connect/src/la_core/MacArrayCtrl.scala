import chisel3._
import chisel3.util._

private object MacArrayCtrlTiming {
  val AccReadLatencyCycles: Int = 3
}

object MacArrayOp {
  val GEMM: Int = 0
  val MUL: Int = 1
  val ADD: Int = 2
}

class MacArrayGEMMCtrl(
  val nArray: Int = 16,
  val sramDepth: Int = 2048,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  require(nArray > 0, "MacArrayGEMMCtrl nArray must be > 0")
  require(sramDepth > 0, "MacArrayGEMMCtrl sramDepth must be > 0")
  require(sramDataWidth > 0, "MacArrayGEMMCtrl sramDataWidth must be > 0")
  require(dimWidth > 0, "MacArrayGEMMCtrl dimWidth must be > 0")

  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(sramDepth)
  private val tileSizeWidth = log2Ceil(nArray + 1)
  private val readSelWidth = math.max(1, log2Ceil(nArray))
  private val accReadLatencyCycles = MacArrayCtrlTiming.AccReadLatencyCycles
  private val waitWidth = math.max(1, log2Ceil(accReadLatencyCycles + 1))
  private val lanesPerWord = sramDataWidth / fpw
  private val laneWidth = math.max(1, log2Ceil(lanesPerWord))
  private val takeWidth = math.max(1, log2Ceil(lanesPerWord + 1))
  private val remWidth = math.max(tileSizeWidth, takeWidth)
  private val elemIndexWidth = dimWidth * 2 + 2

  require(sramDataWidth % fpw == 0, "MacArrayGEMMCtrl sramDataWidth must be multiple of fp16 width")

  val io = IO(new Bundle {
    val start = Input(Bool())
    val nRows = Input(UInt(dimWidth.W))
    val mCols = Input(UInt(dimWidth.W))
    val kDim = Input(UInt(dimWidth.W))

    // Base addresses are word addresses (not byte addresses).
    // Matrices are stored row-major as contiguous elements:
    // - A(NxK): elem index = row*K + col
    // - B(KxM): elem index = row*M + col
    // - C(NxM): elem index = row*M + col
    val baseA = Input(UInt(addrWidth.W))
    val baseB = Input(UInt(addrWidth.W))
    val baseC = Input(UInt(addrWidth.W))

    val busy = Output(Bool())
    val done = Output(Bool())

    val aSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val bSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val cSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
  })

  val macArray = Module(new MacArray(nArray, sigWidth, expWidth, ieeeCompliance, enUbrFlag))

  val nReg = RegInit(0.U(dimWidth.W))
  val mReg = RegInit(0.U(dimWidth.W))
  val kReg = RegInit(0.U(dimWidth.W))
  val baseAReg = RegInit(0.U(addrWidth.W))
  val baseBReg = RegInit(0.U(addrWidth.W))
  val baseCReg = RegInit(0.U(addrWidth.W))

  val tileCountNReg = RegInit(0.U(dimWidth.W))
  val tileCountMReg = RegInit(0.U(dimWidth.W))
  val tileRowIdxReg = RegInit(0.U(dimWidth.W))
  val tileColIdxReg = RegInit(0.U(dimWidth.W))
  val tileRowsReg = RegInit(0.U(tileSizeWidth.W))
  val tileColsReg = RegInit(0.U(tileSizeWidth.W))

  val kCounter = RegInit(0.U(dimWidth.W))
  val rowCounter = RegInit(0.U(readSelWidth.W))
  val colWriteReg = RegInit(0.U(tileSizeWidth.W))
  val flushCounter = RegInit(0.U(waitWidth.W))
  val drainCounter = RegInit(0.U(waitWidth.W))

  val cAsmValidReg = RegInit(false.B)
  val cAsmAddrReg = RegInit(0.U(addrWidth.W))
  val cAsmDataReg = RegInit(0.U(sramDataWidth.W))
  val cAsmBwebReg = RegInit(0.U(sramDataWidth.W))

  val aIdxReg = RegInit(0.U(tileSizeWidth.W))
  val bIdxReg = RegInit(0.U(tileSizeWidth.W))
  val aIssuedValidReg = RegInit(false.B)
  val bIssuedValidReg = RegInit(false.B)
  val aIssuedIdxReg = RegInit(0.U(tileSizeWidth.W))
  val bIssuedIdxReg = RegInit(0.U(tileSizeWidth.W))
  val aIssuedLaneReg = RegInit(0.U(laneWidth.W))
  val bIssuedLaneReg = RegInit(0.U(laneWidth.W))
  val bIssuedTakeReg = RegInit(0.U(takeWidth.W))
  val abPhaseReg = RegInit(false.B) // false: prefer A, true: prefer B

  val aVecBuf = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))
  val bVecBuf = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))
  val rowBuf = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))

  val sIdle :: sClearPulse :: sClearIdle :: sFlush :: sFetchReq :: sFetchResp :: sCompute :: sDrain :: sReadRow :: sWriteC :: sFlushC :: sDone :: Nil = Enum(12)
  val state = RegInit(sIdle)

  private def ceilDiv(value: UInt, divisor: Int): UInt = {
    (value + (divisor - 1).U) / divisor.U
  }

  private def tileSizeFor(total: UInt, tileIdx: UInt): UInt = {
    val base = tileIdx * nArray.U
    val remaining = Mux(total > base, total - base, 0.U)
    Mux(remaining >= nArray.U, nArray.U(tileSizeWidth.W), remaining(tileSizeWidth - 1, 0))
  }

  private def zext(value: UInt, width: Int): UInt = {
    val curWidth = value.getWidth
    if (width <= curWidth) {
      value(width - 1, 0)
    } else {
      Cat(0.U((width - curWidth).W), value)
    }
  }

  private def trimIdx(value: UInt): UInt = {
    value(readSelWidth - 1, 0)
  }

  private def elemIndexA(row: UInt, col: UInt): UInt = {
    val idx = row * kReg + col
    zext(idx, elemIndexWidth)
  }

  private def elemIndexB(row: UInt, col: UInt): UInt = {
    val idx = row * mReg + col
    zext(idx, elemIndexWidth)
  }

  private def elemIndexC(row: UInt, col: UInt): UInt = {
    val idx = row * mReg + col
    zext(idx, elemIndexWidth)
  }

  private def wordAddrForElem(base: UInt, elemIdx: UInt): UInt = {
    val wordOffset = elemIdx / lanesPerWord.U
    (base + wordOffset)(addrWidth - 1, 0)
  }

  private def laneForElem(elemIdx: UInt): UInt = {
    val lane = elemIdx % lanesPerWord.U
    lane(laneWidth - 1, 0)
  }

  private def extractLane(word: UInt, lane: UInt): UInt = {
    Mux1H((0 until lanesPerWord).map(i => (lane === i.U) -> word((i + 1) * fpw - 1, i * fpw)))
  }

  private def buildLaneWriteData(lane: UInt, laneValue: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, laneValue, 0.U(fpw.W)))).asUInt
  }

  private def buildLaneWriteBweb(lane: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, 0.U(fpw.W), Fill(fpw, 1.U(1.W))))).asUInt
  }

  val tileLastCol = tileColIdxReg === (tileCountMReg - 1.U)
  val tileLastRow = tileRowIdxReg === (tileCountNReg - 1.U)

  for (i <- 0 until nArray) {
    macArray.io.aVecIn(i) := 0.U
    macArray.io.bVecIn(i) := 0.U
  }
  macArray.io.funcMode := MacArrayFuncMode.IDLE
  macArray.io.computeEn := false.B
  macArray.io.accClearPulse := false.B
  macArray.io.tileRows := tileRowsReg
  macArray.io.tileCols := tileColsReg
  macArray.io.readEn := false.B
  macArray.io.readByCol := false.B
  macArray.io.readSel := rowCounter

  io.aSram.enable := false.B
  io.aSram.addr := 0.U
  io.aSram.write := false.B
  io.aSram.dataIn := 0.U
  io.aSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.bSram.enable := false.B
  io.bSram.addr := 0.U
  io.bSram.write := false.B
  io.bSram.dataIn := 0.U
  io.bSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.cSram.enable := false.B
  io.cSram.addr := 0.U
  io.cSram.write := false.B
  io.cSram.dataIn := 0.U
  io.cSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  switch(state) {
    is(sIdle) {
      when(io.start) {
        nReg := io.nRows
        mReg := io.mCols
        kReg := io.kDim
        baseAReg := io.baseA
        baseBReg := io.baseB
        baseCReg := io.baseC

        tileCountNReg := ceilDiv(io.nRows, nArray)
        tileCountMReg := ceilDiv(io.mCols, nArray)
        tileRowIdxReg := 0.U
        tileColIdxReg := 0.U
        tileRowsReg := tileSizeFor(io.nRows, 0.U)
        tileColsReg := tileSizeFor(io.mCols, 0.U)

        kCounter := 0.U
        rowCounter := 0.U
        colWriteReg := 0.U
        flushCounter := 0.U
        drainCounter := 0.U
        aIdxReg := 0.U
        bIdxReg := 0.U
        bIssuedTakeReg := 0.U
        abPhaseReg := false.B
        cAsmValidReg := false.B
        cAsmAddrReg := 0.U
        cAsmDataReg := 0.U
        cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))

        val hasWork = (io.nRows =/= 0.U) && (io.mCols =/= 0.U) && (io.kDim =/= 0.U)
        state := Mux(hasWork, sClearPulse, sDone)
      }
    }

    is(sClearPulse) {
      macArray.io.accClearPulse := true.B
      state := sClearIdle
    }

    is(sClearIdle) {
      flushCounter := 0.U
      state := sFlush
    }

    is(sFlush) {
      macArray.io.funcMode := MacArrayFuncMode.MAC
      macArray.io.computeEn := true.B
      when(flushCounter === (accReadLatencyCycles - 1).U) {
        flushCounter := 0.U
        kCounter := 0.U
        aIdxReg := 0.U
        bIdxReg := 0.U
        state := sFetchReq
      }.otherwise {
        flushCounter := flushCounter + 1.U
      }
    }

    is(sFetchReq) {
      val aNeed = aIdxReg < tileRowsReg
      val bNeed = bIdxReg < tileColsReg

      val aGlobalRow = (tileRowIdxReg * nArray.U) + aIdxReg
      val bGlobalCol = (tileColIdxReg * nArray.U) + bIdxReg

      val aElemIdx = elemIndexA(aGlobalRow, kCounter)
      val bElemIdx = elemIndexB(kCounter, bGlobalCol)

      val aLane = laneForElem(aElemIdx)
      val bLane = laneForElem(bElemIdx)
      val lanesAvail = zext(lanesPerWord.U - bLane, remWidth)
      val colsRemain = zext(tileColsReg - bIdxReg, remWidth)
      val takeWide = Mux(lanesAvail < colsRemain, lanesAvail, colsRemain)
      val bTake = takeWide(takeWidth - 1, 0)

      val doA = aNeed && (!bNeed || !abPhaseReg)
      val doB = bNeed && (!aNeed || abPhaseReg)

      io.aSram.enable := doA
      io.aSram.addr := wordAddrForElem(baseAReg, aElemIdx)
      io.aSram.write := false.B
      io.aSram.bweb := Fill(sramDataWidth, 1.U(1.W))

      io.bSram.enable := doB
      io.bSram.addr := wordAddrForElem(baseBReg, bElemIdx)
      io.bSram.write := false.B
      io.bSram.bweb := Fill(sramDataWidth, 1.U(1.W))

      aIssuedValidReg := doA
      bIssuedValidReg := doB
      aIssuedIdxReg := aIdxReg
      bIssuedIdxReg := bIdxReg
      aIssuedLaneReg := aLane
      bIssuedLaneReg := bLane
      bIssuedTakeReg := Mux(doB, bTake, 0.U)

      when(doA && bNeed) {
        abPhaseReg := true.B
      }.elsewhen(doB && aNeed) {
        abPhaseReg := false.B
      }

      when(doA || doB) {
        state := sFetchResp
      }.otherwise {
        state := sCompute
      }
    }

    is(sFetchResp) {
      val aIdxNext = aIdxReg + Mux(aIssuedValidReg, 1.U, 0.U)
      val bIdxNext = (bIdxReg + Mux(bIssuedValidReg, bIssuedTakeReg, 0.U))(tileSizeWidth - 1, 0)

      when(aIssuedValidReg) {
        aVecBuf(trimIdx(aIssuedIdxReg)) := extractLane(io.aSram.dataOut, aIssuedLaneReg)
      }
      when(bIssuedValidReg) {
        for (i <- 0 until nArray) {
          when((i.U >= bIssuedIdxReg) && (i.U < (bIssuedIdxReg + bIssuedTakeReg))) {
            val laneOffset = (i.U - bIssuedIdxReg)(laneWidth - 1, 0)
            val laneSel = (bIssuedLaneReg + laneOffset)(laneWidth - 1, 0)
            bVecBuf(i) := extractLane(io.bSram.dataOut, laneSel)
          }
        }
      }

      aIdxReg := aIdxNext
      bIdxReg := bIdxNext

      val aDone = aIdxNext >= tileRowsReg
      val bDone = bIdxNext >= tileColsReg
      state := Mux(aDone && bDone, sCompute, sFetchReq)
    }

    is(sCompute) {
      macArray.io.funcMode := MacArrayFuncMode.MAC
      macArray.io.computeEn := true.B
      for (i <- 0 until nArray) {
        macArray.io.aVecIn(i) := Mux(i.U < tileRowsReg, aVecBuf(i), 0.U)
        macArray.io.bVecIn(i) := Mux(i.U < tileColsReg, bVecBuf(i), 0.U)
      }

      when(kCounter === (kReg - 1.U)) {
        kCounter := 0.U
        drainCounter := 0.U
        state := sDrain
      }.otherwise {
        kCounter := kCounter + 1.U
        aIdxReg := 0.U
        bIdxReg := 0.U
        state := sFetchReq
      }
    }

    is(sDrain) {
      macArray.io.funcMode := MacArrayFuncMode.MAC
      macArray.io.computeEn := true.B
      when(drainCounter === (accReadLatencyCycles - 1).U) {
        drainCounter := 0.U
        rowCounter := 0.U
        state := sReadRow
      }.otherwise {
        drainCounter := drainCounter + 1.U
      }
    }

    is(sReadRow) {
      macArray.io.readEn := true.B
      macArray.io.readByCol := false.B
      macArray.io.readSel := rowCounter

      for (i <- 0 until nArray) {
        rowBuf(i) := macArray.io.readPackOut((i + 1) * fpw - 1, i * fpw)
      }

      colWriteReg := 0.U
      cAsmValidReg := false.B
      cAsmAddrReg := 0.U
      cAsmDataReg := 0.U
      cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))
      state := sWriteC
    }

    is(sWriteC) {
      val writeValid = colWriteReg < tileColsReg
      val globalRow = (tileRowIdxReg * nArray.U) + rowCounter
      val globalCol = (tileColIdxReg * nArray.U) + colWriteReg
      val elemIdx = elemIndexC(globalRow, globalCol)
      val lane = laneForElem(elemIdx)
      val curWordAddr = wordAddrForElem(baseCReg, elemIdx)
      val curWriteData = buildLaneWriteData(lane, rowBuf(trimIdx(colWriteReg)))
      val curWriteBweb = buildLaneWriteBweb(lane)

      val lastElem = writeValid && (colWriteReg === (tileColsReg - 1.U))
      val sameWord = cAsmValidReg && (cAsmAddrReg === curWordAddr)
      val needEmit = cAsmValidReg && writeValid && !sameWord
      val emitAddr = cAsmAddrReg
      val emitData = cAsmDataReg
      val emitBweb = cAsmBwebReg

      io.cSram.enable := needEmit
      io.cSram.addr := emitAddr
      io.cSram.write := needEmit
      io.cSram.dataIn := emitData
      io.cSram.bweb := emitBweb

      when(writeValid) {
        when(!cAsmValidReg) {
          cAsmValidReg := true.B
          cAsmAddrReg := curWordAddr
          cAsmDataReg := curWriteData
          cAsmBwebReg := curWriteBweb
        }.elsewhen(sameWord) {
          cAsmDataReg := (cAsmDataReg & curWriteBweb) | curWriteData
          cAsmBwebReg := cAsmBwebReg & curWriteBweb
        }.otherwise {
          cAsmValidReg := true.B
          cAsmAddrReg := curWordAddr
          cAsmDataReg := curWriteData
          cAsmBwebReg := curWriteBweb
        }

        when(lastElem) {
          state := sFlushC
        }.otherwise {
          colWriteReg := colWriteReg + 1.U
        }
      }.otherwise {
        state := sFlushC
      }
    }

    is(sFlushC) {
      io.cSram.enable := cAsmValidReg
      io.cSram.addr := cAsmAddrReg
      io.cSram.write := cAsmValidReg
      io.cSram.dataIn := cAsmDataReg
      io.cSram.bweb := cAsmBwebReg

      cAsmValidReg := false.B
      cAsmAddrReg := 0.U
      cAsmDataReg := 0.U
      cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))

      when(rowCounter === (tileRowsReg - 1.U)) {
        rowCounter := 0.U
        when(tileLastCol && tileLastRow) {
          state := sDone
        }.otherwise {
          val nextTileCol = Mux(tileLastCol, 0.U, tileColIdxReg + 1.U)
          val nextTileRow = Mux(tileLastCol, tileRowIdxReg + 1.U, tileRowIdxReg)
          tileColIdxReg := nextTileCol
          tileRowIdxReg := nextTileRow
          tileRowsReg := tileSizeFor(nReg, nextTileRow)
          tileColsReg := tileSizeFor(mReg, nextTileCol)
          flushCounter := 0.U
          drainCounter := 0.U
          kCounter := 0.U
          aIdxReg := 0.U
          bIdxReg := 0.U
          state := sClearPulse
        }
      }.otherwise {
        rowCounter := rowCounter + 1.U
        state := sReadRow
      }
    }

    is(sDone) {
      state := sIdle
    }
  }

  io.busy := (state =/= sIdle) && (state =/= sDone)
  io.done := state === sDone
}

class MacArrayMULCtrl(
  val nArray: Int = 16,
  val sramDepth: Int = 2048,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  require(nArray > 0, "MacArrayMULCtrl nArray must be > 0")
  require(sramDepth > 0, "MacArrayMULCtrl sramDepth must be > 0")
  require(sramDataWidth > 0, "MacArrayMULCtrl sramDataWidth must be > 0")
  require(dimWidth > 0, "MacArrayMULCtrl dimWidth must be > 0")

  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(sramDepth)
  private val tileSizeWidth = log2Ceil(nArray + 1)
  private val readSelWidth = math.max(1, log2Ceil(nArray))
  private val accReadLatencyCycles = MacArrayCtrlTiming.AccReadLatencyCycles
  private val waitWidth = math.max(1, log2Ceil(accReadLatencyCycles + 1))
  private val lanesPerWord = sramDataWidth / fpw
  private val laneWidth = math.max(1, log2Ceil(lanesPerWord))
  private val takeWidth = math.max(1, log2Ceil(lanesPerWord + 1))
  private val remWidth = math.max(tileSizeWidth, takeWidth)
  private val elemIndexWidth = dimWidth * 2 + 2

  require(sramDataWidth % fpw == 0, "MacArrayMULCtrl sramDataWidth must be multiple of fp16 width")

  val io = IO(new Bundle {
    val start = Input(Bool())
    val nRows = Input(UInt(dimWidth.W))
    val mCols = Input(UInt(dimWidth.W))
    val alpha = Input(UInt(fpw.W))

    // Base addresses are word addresses (not byte addresses).
    // Matrices are stored row-major as contiguous elements:
    // - A(NxM): elem index = row*M + col
    // - C(NxM): elem index = row*M + col
    val baseA = Input(UInt(addrWidth.W))
    val baseC = Input(UInt(addrWidth.W))

    val busy = Output(Bool())
    val done = Output(Bool())

    val aSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val cSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
  })

  val macArray = Module(new MacArray(nArray, sigWidth, expWidth, ieeeCompliance, enUbrFlag))

  val nReg = RegInit(0.U(dimWidth.W))
  val mReg = RegInit(0.U(dimWidth.W))
  val baseAReg = RegInit(0.U(addrWidth.W))
  val baseCReg = RegInit(0.U(addrWidth.W))
  val alphaReg = RegInit(0.U(fpw.W))

  val tileCountMReg = RegInit(0.U(dimWidth.W))
  val tileColIdxReg = RegInit(0.U(dimWidth.W))
  val tileColsReg = RegInit(0.U(tileSizeWidth.W))

  val rowIdxReg = RegInit(0.U(dimWidth.W))
  val colReadIdxReg = RegInit(0.U(tileSizeWidth.W))
  val colWriteReg = RegInit(0.U(tileSizeWidth.W))
  val drainCounter = RegInit(0.U(waitWidth.W))

  val cAsmValidReg = RegInit(false.B)
  val cAsmAddrReg = RegInit(0.U(addrWidth.W))
  val cAsmDataReg = RegInit(0.U(sramDataWidth.W))
  val cAsmBwebReg = RegInit(0.U(sramDataWidth.W))

  val aIssuedValidReg = RegInit(false.B)
  val aIssuedIdxReg = RegInit(0.U(tileSizeWidth.W))
  val aIssuedLaneReg = RegInit(0.U(laneWidth.W))
  val aIssuedTakeReg = RegInit(0.U(takeWidth.W))

  val rowBuf = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))

  val sIdle :: sClearPulse :: sClearIdle :: sFetchReq :: sFetchResp :: sCompute :: sDrain :: sReadRow :: sWriteC :: sFlushC :: sDone :: Nil = Enum(11)
  val state = RegInit(sIdle)

  private def ceilDiv(value: UInt, divisor: Int): UInt = {
    (value + (divisor - 1).U) / divisor.U
  }

  private def tileSizeFor(total: UInt, tileIdx: UInt): UInt = {
    val base = tileIdx * nArray.U
    val remaining = Mux(total > base, total - base, 0.U)
    Mux(remaining >= nArray.U, nArray.U(tileSizeWidth.W), remaining(tileSizeWidth - 1, 0))
  }

  private def zext(value: UInt, width: Int): UInt = {
    val curWidth = value.getWidth
    if (width <= curWidth) {
      value(width - 1, 0)
    } else {
      Cat(0.U((width - curWidth).W), value)
    }
  }

  private def trimIdx(value: UInt): UInt = {
    value(readSelWidth - 1, 0)
  }

  private def elemIndexA(row: UInt, col: UInt): UInt = {
    val idx = row * mReg + col
    zext(idx, elemIndexWidth)
  }

  private def elemIndexC(row: UInt, col: UInt): UInt = {
    val idx = row * mReg + col
    zext(idx, elemIndexWidth)
  }

  private def wordAddrForElem(base: UInt, elemIdx: UInt): UInt = {
    val wordOffset = elemIdx / lanesPerWord.U
    (base + wordOffset)(addrWidth - 1, 0)
  }

  private def laneForElem(elemIdx: UInt): UInt = {
    val lane = elemIdx % lanesPerWord.U
    lane(laneWidth - 1, 0)
  }

  private def extractLane(word: UInt, lane: UInt): UInt = {
    Mux1H((0 until lanesPerWord).map(i => (lane === i.U) -> word((i + 1) * fpw - 1, i * fpw)))
  }

  private def buildLaneWriteData(lane: UInt, laneValue: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, laneValue, 0.U(fpw.W)))).asUInt
  }

  private def buildLaneWriteBweb(lane: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, 0.U(fpw.W), Fill(fpw, 1.U(1.W))))).asUInt
  }

  val tileLastCol = tileColIdxReg === (tileCountMReg - 1.U)
  val rowLast = rowIdxReg === (nReg - 1.U)

  for (i <- 0 until nArray) {
    macArray.io.aVecIn(i) := 0.U
    macArray.io.bVecIn(i) := 0.U
  }
  macArray.io.funcMode := MacArrayFuncMode.IDLE
  macArray.io.computeEn := false.B
  macArray.io.accClearPulse := false.B
  macArray.io.tileRows := 1.U
  macArray.io.tileCols := tileColsReg
  macArray.io.readEn := false.B
  macArray.io.readByCol := false.B
  macArray.io.readSel := 0.U

  io.aSram.enable := false.B
  io.aSram.addr := 0.U
  io.aSram.write := false.B
  io.aSram.dataIn := 0.U
  io.aSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.cSram.enable := false.B
  io.cSram.addr := 0.U
  io.cSram.write := false.B
  io.cSram.dataIn := 0.U
  io.cSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  switch(state) {
    is(sIdle) {
      when(io.start) {
        nReg := io.nRows
        mReg := io.mCols
        baseAReg := io.baseA
        baseCReg := io.baseC
        alphaReg := io.alpha

        tileCountMReg := ceilDiv(io.mCols, nArray)
        tileColIdxReg := 0.U
        tileColsReg := tileSizeFor(io.mCols, 0.U)
        rowIdxReg := 0.U

        colReadIdxReg := 0.U
        colWriteReg := 0.U
        drainCounter := 0.U

        cAsmValidReg := false.B
        cAsmAddrReg := 0.U
        cAsmDataReg := 0.U
        cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))

        aIssuedValidReg := false.B
        aIssuedIdxReg := 0.U
        aIssuedLaneReg := 0.U
        aIssuedTakeReg := 0.U

        val hasWork = (io.nRows =/= 0.U) && (io.mCols =/= 0.U)
        state := Mux(hasWork, sClearPulse, sDone)
      }
    }

    is(sClearPulse) {
      macArray.io.accClearPulse := true.B
      state := sClearIdle
    }

    is(sClearIdle) {
      colReadIdxReg := 0.U
      state := sFetchReq
    }

    is(sFetchReq) {
      val needRead = colReadIdxReg < tileColsReg
      val globalCol = (tileColIdxReg * nArray.U) + colReadIdxReg
      val elemIdx = elemIndexA(rowIdxReg, globalCol)
      val lane = laneForElem(elemIdx)

      val lanesAvail = zext(lanesPerWord.U - lane, remWidth)
      val colsRemain = zext(tileColsReg - colReadIdxReg, remWidth)
      val takeWide = Mux(lanesAvail < colsRemain, lanesAvail, colsRemain)
      val take = takeWide(takeWidth - 1, 0)

      io.aSram.enable := needRead
      io.aSram.addr := wordAddrForElem(baseAReg, elemIdx)
      io.aSram.write := false.B
      io.aSram.bweb := Fill(sramDataWidth, 1.U(1.W))

      aIssuedValidReg := needRead
      aIssuedIdxReg := colReadIdxReg
      aIssuedLaneReg := lane
      aIssuedTakeReg := Mux(needRead, take, 0.U)

      state := Mux(needRead, sFetchResp, sCompute)
    }

    is(sFetchResp) {
      val colIdxNext = (colReadIdxReg + Mux(aIssuedValidReg, aIssuedTakeReg, 0.U))(tileSizeWidth - 1, 0)

      when(aIssuedValidReg) {
        for (i <- 0 until nArray) {
          when((i.U >= aIssuedIdxReg) && (i.U < (aIssuedIdxReg + aIssuedTakeReg))) {
            val laneOffset = (i.U - aIssuedIdxReg)(laneWidth - 1, 0)
            val laneSel = (aIssuedLaneReg + laneOffset)(laneWidth - 1, 0)
            rowBuf(i) := extractLane(io.aSram.dataOut, laneSel)
          }
        }
      }

      colReadIdxReg := colIdxNext

      val done = colIdxNext >= tileColsReg
      state := Mux(done, sCompute, sFetchReq)
    }

    is(sCompute) {
      macArray.io.funcMode := MacArrayFuncMode.MUL
      macArray.io.computeEn := true.B
      macArray.io.aVecIn(0) := alphaReg
      for (i <- 0 until nArray) {
        macArray.io.bVecIn(i) := Mux(i.U < tileColsReg, rowBuf(i), 0.U)
      }
      drainCounter := 0.U
      state := sDrain
    }

    is(sDrain) {
      macArray.io.funcMode := MacArrayFuncMode.MUL
      macArray.io.computeEn := true.B
      macArray.io.aVecIn(0) := alphaReg
      for (i <- 0 until nArray) {
        macArray.io.bVecIn(i) := Mux(i.U < tileColsReg, rowBuf(i), 0.U)
      }
      when(drainCounter === (accReadLatencyCycles - 1).U) {
        drainCounter := 0.U
        state := sReadRow
      }.otherwise {
        drainCounter := drainCounter + 1.U
      }
    }

    is(sReadRow) {
      macArray.io.readEn := true.B
      macArray.io.readByCol := false.B
      macArray.io.readSel := 0.U
      for (i <- 0 until nArray) {
        rowBuf(i) := macArray.io.readPackOut((i + 1) * fpw - 1, i * fpw)
      }
      colWriteReg := 0.U
      cAsmValidReg := false.B
      cAsmAddrReg := 0.U
      cAsmDataReg := 0.U
      cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))
      state := sWriteC
    }

    is(sWriteC) {
      val writeValid = colWriteReg < tileColsReg
      val globalRow = rowIdxReg
      val globalCol = (tileColIdxReg * nArray.U) + colWriteReg
      val elemIdx = elemIndexC(globalRow, globalCol)
      val lane = laneForElem(elemIdx)
      val curWordAddr = wordAddrForElem(baseCReg, elemIdx)
      val curWriteData = buildLaneWriteData(lane, rowBuf(trimIdx(colWriteReg)))
      val curWriteBweb = buildLaneWriteBweb(lane)

      val lastElem = writeValid && (colWriteReg === (tileColsReg - 1.U))
      val sameWord = cAsmValidReg && (cAsmAddrReg === curWordAddr)
      val needEmit = cAsmValidReg && writeValid && !sameWord
      val emitAddr = cAsmAddrReg
      val emitData = cAsmDataReg
      val emitBweb = cAsmBwebReg

      io.cSram.enable := needEmit
      io.cSram.addr := emitAddr
      io.cSram.write := needEmit
      io.cSram.dataIn := emitData
      io.cSram.bweb := emitBweb

      when(writeValid) {
        when(!cAsmValidReg) {
          cAsmValidReg := true.B
          cAsmAddrReg := curWordAddr
          cAsmDataReg := curWriteData
          cAsmBwebReg := curWriteBweb
        }.elsewhen(sameWord) {
          cAsmDataReg := (cAsmDataReg & curWriteBweb) | curWriteData
          cAsmBwebReg := cAsmBwebReg & curWriteBweb
        }.otherwise {
          cAsmValidReg := true.B
          cAsmAddrReg := curWordAddr
          cAsmDataReg := curWriteData
          cAsmBwebReg := curWriteBweb
        }

        when(lastElem) {
          state := sFlushC
        }.otherwise {
          colWriteReg := colWriteReg + 1.U
        }
      }.otherwise {
        state := sFlushC
      }
    }

    is(sFlushC) {
      io.cSram.enable := cAsmValidReg
      io.cSram.addr := cAsmAddrReg
      io.cSram.write := cAsmValidReg
      io.cSram.dataIn := cAsmDataReg
      io.cSram.bweb := cAsmBwebReg

      cAsmValidReg := false.B
      cAsmAddrReg := 0.U
      cAsmDataReg := 0.U
      cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))

      when(rowLast) {
        when(tileLastCol) {
          state := sDone
        }.otherwise {
          val nextTileCol = tileColIdxReg + 1.U
          tileColIdxReg := nextTileCol
          tileColsReg := tileSizeFor(mReg, nextTileCol)
          rowIdxReg := 0.U
          colReadIdxReg := 0.U
          state := sFetchReq
        }
      }.otherwise {
        rowIdxReg := rowIdxReg + 1.U
        colReadIdxReg := 0.U
        state := sFetchReq
      }
    }

    is(sDone) {
      state := sIdle
    }
  }

  io.busy := (state =/= sIdle) && (state =/= sDone)
  io.done := state === sDone
}

class MacArrayADDCtrl(
  val nArray: Int = 16,
  val sramDepth: Int = 2048,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  require(nArray > 0, "MacArrayADDCtrl nArray must be > 0")
  require(sramDepth > 0, "MacArrayADDCtrl sramDepth must be > 0")
  require(sramDataWidth > 0, "MacArrayADDCtrl sramDataWidth must be > 0")
  require(dimWidth > 0, "MacArrayADDCtrl dimWidth must be > 0")

  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(sramDepth)
  private val tileSizeWidth = log2Ceil(nArray + 1)
  private val readSelWidth = math.max(1, log2Ceil(nArray))
  private val accReadLatencyCycles = MacArrayCtrlTiming.AccReadLatencyCycles
  private val waitWidth = math.max(1, log2Ceil(accReadLatencyCycles + 1))
  private val lanesPerWord = sramDataWidth / fpw
  private val laneWidth = math.max(1, log2Ceil(lanesPerWord))
  private val takeWidth = math.max(1, log2Ceil(lanesPerWord + 1))
  private val remWidth = math.max(tileSizeWidth, takeWidth)
  private val elemIndexWidth = dimWidth * 2 + 2

  require(sramDataWidth % fpw == 0, "MacArrayADDCtrl sramDataWidth must be multiple of fp16 width")

  val io = IO(new Bundle {
    val start = Input(Bool())
    val nRows = Input(UInt(dimWidth.W))
    val mCols = Input(UInt(dimWidth.W))

    // Base addresses are word addresses (not byte addresses).
    // Matrices are stored row-major as contiguous elements:
    // - A(NxM): elem index = row*M + col
    // - B(NxM): elem index = row*M + col
    // - C(NxM): elem index = row*M + col
    val baseA = Input(UInt(addrWidth.W))
    val baseB = Input(UInt(addrWidth.W))
    val baseC = Input(UInt(addrWidth.W))

    val busy = Output(Bool())
    val done = Output(Bool())

    val aSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val bSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val cSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
  })

  val macArray = Module(new MacArray(nArray, sigWidth, expWidth, ieeeCompliance, enUbrFlag))

  val nReg = RegInit(0.U(dimWidth.W))
  val mReg = RegInit(0.U(dimWidth.W))
  val baseAReg = RegInit(0.U(addrWidth.W))
  val baseBReg = RegInit(0.U(addrWidth.W))
  val baseCReg = RegInit(0.U(addrWidth.W))

  val tileCountMReg = RegInit(0.U(dimWidth.W))
  val tileColIdxReg = RegInit(0.U(dimWidth.W))
  val tileColsReg = RegInit(0.U(tileSizeWidth.W))

  val rowIdxReg = RegInit(0.U(dimWidth.W))
  val colReadIdxReg = RegInit(0.U(tileSizeWidth.W))
  val colWriteReg = RegInit(0.U(tileSizeWidth.W))
  val drainCounter = RegInit(0.U(waitWidth.W))

  val cAsmValidReg = RegInit(false.B)
  val cAsmAddrReg = RegInit(0.U(addrWidth.W))
  val cAsmDataReg = RegInit(0.U(sramDataWidth.W))
  val cAsmBwebReg = RegInit(0.U(sramDataWidth.W))

  val issuedValidReg = RegInit(false.B)
  val issuedIdxReg = RegInit(0.U(tileSizeWidth.W))
  val issuedLaneReg = RegInit(0.U(laneWidth.W))
  val issuedTakeReg = RegInit(0.U(takeWidth.W))

  val rowBufA = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))
  val rowBufB = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))
  val outBuf = RegInit(VecInit(Seq.fill(nArray)(0.U(fpw.W))))

  val sIdle :: sClearPulse :: sClearIdle :: sFetchAReq :: sFetchAResp :: sFetchBReq :: sFetchBResp :: sComputeA :: sComputeB :: sDrain :: sReadRow :: sWriteC :: sFlushC :: sDone :: Nil = Enum(14)
  val state = RegInit(sIdle)

  private def ceilDiv(value: UInt, divisor: Int): UInt = {
    (value + (divisor - 1).U) / divisor.U
  }

  private def tileSizeFor(total: UInt, tileIdx: UInt): UInt = {
    val base = tileIdx * nArray.U
    val remaining = Mux(total > base, total - base, 0.U)
    Mux(remaining >= nArray.U, nArray.U(tileSizeWidth.W), remaining(tileSizeWidth - 1, 0))
  }

  private def zext(value: UInt, width: Int): UInt = {
    val curWidth = value.getWidth
    if (width <= curWidth) {
      value(width - 1, 0)
    } else {
      Cat(0.U((width - curWidth).W), value)
    }
  }

  private def trimIdx(value: UInt): UInt = {
    value(readSelWidth - 1, 0)
  }

  private def elemIndex(row: UInt, col: UInt): UInt = {
    val idx = row * mReg + col
    zext(idx, elemIndexWidth)
  }

  private def wordAddrForElem(base: UInt, elemIdx: UInt): UInt = {
    val wordOffset = elemIdx / lanesPerWord.U
    (base + wordOffset)(addrWidth - 1, 0)
  }

  private def laneForElem(elemIdx: UInt): UInt = {
    val lane = elemIdx % lanesPerWord.U
    lane(laneWidth - 1, 0)
  }

  private def extractLane(word: UInt, lane: UInt): UInt = {
    Mux1H((0 until lanesPerWord).map(i => (lane === i.U) -> word((i + 1) * fpw - 1, i * fpw)))
  }

  private def buildLaneWriteData(lane: UInt, laneValue: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, laneValue, 0.U(fpw.W)))).asUInt
  }

  private def buildLaneWriteBweb(lane: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, 0.U(fpw.W), Fill(fpw, 1.U(1.W))))).asUInt
  }

  val tileLastCol = tileColIdxReg === (tileCountMReg - 1.U)
  val rowLast = rowIdxReg === (nReg - 1.U)

  for (i <- 0 until nArray) {
    macArray.io.aVecIn(i) := 0.U
    macArray.io.bVecIn(i) := 0.U
  }
  macArray.io.funcMode := MacArrayFuncMode.IDLE
  macArray.io.computeEn := false.B
  macArray.io.accClearPulse := false.B
  macArray.io.tileRows := 1.U
  macArray.io.tileCols := tileColsReg
  macArray.io.readEn := false.B
  macArray.io.readByCol := false.B
  macArray.io.readSel := 0.U

  io.aSram.enable := false.B
  io.aSram.addr := 0.U
  io.aSram.write := false.B
  io.aSram.dataIn := 0.U
  io.aSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.bSram.enable := false.B
  io.bSram.addr := 0.U
  io.bSram.write := false.B
  io.bSram.dataIn := 0.U
  io.bSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.cSram.enable := false.B
  io.cSram.addr := 0.U
  io.cSram.write := false.B
  io.cSram.dataIn := 0.U
  io.cSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  switch(state) {
    is(sIdle) {
      when(io.start) {
        nReg := io.nRows
        mReg := io.mCols
        baseAReg := io.baseA
        baseBReg := io.baseB
        baseCReg := io.baseC

        tileCountMReg := ceilDiv(io.mCols, nArray)
        tileColIdxReg := 0.U
        tileColsReg := tileSizeFor(io.mCols, 0.U)
        rowIdxReg := 0.U

        colReadIdxReg := 0.U
        colWriteReg := 0.U
        drainCounter := 0.U

        cAsmValidReg := false.B
        cAsmAddrReg := 0.U
        cAsmDataReg := 0.U
        cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))

        issuedValidReg := false.B
        issuedIdxReg := 0.U
        issuedLaneReg := 0.U
        issuedTakeReg := 0.U

        val hasWork = (io.nRows =/= 0.U) && (io.mCols =/= 0.U)
        state := Mux(hasWork, sClearPulse, sDone)
      }
    }

    is(sClearPulse) {
      macArray.io.accClearPulse := true.B
      state := sClearIdle
    }

    is(sClearIdle) {
      colReadIdxReg := 0.U
      state := sFetchAReq
    }

    is(sFetchAReq) {
      val needRead = colReadIdxReg < tileColsReg
      val globalCol = (tileColIdxReg * nArray.U) + colReadIdxReg
      val elemIdx = elemIndex(rowIdxReg, globalCol)
      val lane = laneForElem(elemIdx)

      val lanesAvail = zext(lanesPerWord.U - lane, remWidth)
      val colsRemain = zext(tileColsReg - colReadIdxReg, remWidth)
      val takeWide = Mux(lanesAvail < colsRemain, lanesAvail, colsRemain)
      val take = takeWide(takeWidth - 1, 0)

      io.aSram.enable := needRead
      io.aSram.addr := wordAddrForElem(baseAReg, elemIdx)
      io.aSram.write := false.B
      io.aSram.bweb := Fill(sramDataWidth, 1.U(1.W))

      issuedValidReg := needRead
      issuedIdxReg := colReadIdxReg
      issuedLaneReg := lane
      issuedTakeReg := Mux(needRead, take, 0.U)

      state := Mux(needRead, sFetchAResp, sFetchBReq)
    }

    is(sFetchAResp) {
      val colIdxNext = (colReadIdxReg + Mux(issuedValidReg, issuedTakeReg, 0.U))(tileSizeWidth - 1, 0)

      when(issuedValidReg) {
        for (i <- 0 until nArray) {
          when((i.U >= issuedIdxReg) && (i.U < (issuedIdxReg + issuedTakeReg))) {
            val laneOffset = (i.U - issuedIdxReg)(laneWidth - 1, 0)
            val laneSel = (issuedLaneReg + laneOffset)(laneWidth - 1, 0)
            rowBufA(i) := extractLane(io.aSram.dataOut, laneSel)
          }
        }
      }

      val done = colIdxNext >= tileColsReg
      colReadIdxReg := Mux(done, 0.U, colIdxNext)
      state := Mux(done, sFetchBReq, sFetchAReq)
    }

    is(sFetchBReq) {
      val needRead = colReadIdxReg < tileColsReg
      val globalCol = (tileColIdxReg * nArray.U) + colReadIdxReg
      val elemIdx = elemIndex(rowIdxReg, globalCol)
      val lane = laneForElem(elemIdx)

      val lanesAvail = zext(lanesPerWord.U - lane, remWidth)
      val colsRemain = zext(tileColsReg - colReadIdxReg, remWidth)
      val takeWide = Mux(lanesAvail < colsRemain, lanesAvail, colsRemain)
      val take = takeWide(takeWidth - 1, 0)

      io.bSram.enable := needRead
      io.bSram.addr := wordAddrForElem(baseBReg, elemIdx)
      io.bSram.write := false.B
      io.bSram.bweb := Fill(sramDataWidth, 1.U(1.W))

      issuedValidReg := needRead
      issuedIdxReg := colReadIdxReg
      issuedLaneReg := lane
      issuedTakeReg := Mux(needRead, take, 0.U)

      state := Mux(needRead, sFetchBResp, sComputeA)
    }

    is(sFetchBResp) {
      val colIdxNext = (colReadIdxReg + Mux(issuedValidReg, issuedTakeReg, 0.U))(tileSizeWidth - 1, 0)

      when(issuedValidReg) {
        for (i <- 0 until nArray) {
          when((i.U >= issuedIdxReg) && (i.U < (issuedIdxReg + issuedTakeReg))) {
            val laneOffset = (i.U - issuedIdxReg)(laneWidth - 1, 0)
            val laneSel = (issuedLaneReg + laneOffset)(laneWidth - 1, 0)
            rowBufB(i) := extractLane(io.bSram.dataOut, laneSel)
          }
        }
      }

      colReadIdxReg := colIdxNext
      val done = colIdxNext >= tileColsReg
      state := Mux(done, sComputeA, sFetchBReq)
    }

    is(sComputeA) {
      macArray.io.funcMode := MacArrayFuncMode.ACC
      macArray.io.computeEn := true.B
      for (i <- 0 until nArray) {
        macArray.io.bVecIn(i) := Mux(i.U < tileColsReg, rowBufA(i), 0.U)
      }
      state := sComputeB
    }

    is(sComputeB) {
      macArray.io.funcMode := MacArrayFuncMode.ACC
      macArray.io.computeEn := true.B
      for (i <- 0 until nArray) {
        macArray.io.bVecIn(i) := Mux(i.U < tileColsReg, rowBufB(i), 0.U)
      }
      drainCounter := 0.U
      state := sDrain
    }

    is(sDrain) {
      macArray.io.funcMode := MacArrayFuncMode.ACC
      macArray.io.computeEn := true.B
      for (i <- 0 until nArray) {
        macArray.io.bVecIn(i) := 0.U
      }
      when(drainCounter === (accReadLatencyCycles - 1).U) {
        drainCounter := 0.U
        state := sReadRow
      }.otherwise {
        drainCounter := drainCounter + 1.U
      }
    }

    is(sReadRow) {
      macArray.io.readEn := true.B
      macArray.io.readByCol := false.B
      macArray.io.readSel := 0.U
      for (i <- 0 until nArray) {
        outBuf(i) := macArray.io.readPackOut((i + 1) * fpw - 1, i * fpw)
      }
      colWriteReg := 0.U
      cAsmValidReg := false.B
      cAsmAddrReg := 0.U
      cAsmDataReg := 0.U
      cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))
      state := sWriteC
    }

    is(sWriteC) {
      val writeValid = colWriteReg < tileColsReg
      val globalRow = rowIdxReg
      val globalCol = (tileColIdxReg * nArray.U) + colWriteReg
      val elemIdx = elemIndex(globalRow, globalCol)
      val lane = laneForElem(elemIdx)
      val curWordAddr = wordAddrForElem(baseCReg, elemIdx)
      val curWriteData = buildLaneWriteData(lane, outBuf(trimIdx(colWriteReg)))
      val curWriteBweb = buildLaneWriteBweb(lane)

      val lastElem = writeValid && (colWriteReg === (tileColsReg - 1.U))
      val sameWord = cAsmValidReg && (cAsmAddrReg === curWordAddr)
      val needEmit = cAsmValidReg && writeValid && !sameWord
      val emitAddr = cAsmAddrReg
      val emitData = cAsmDataReg
      val emitBweb = cAsmBwebReg

      io.cSram.enable := needEmit
      io.cSram.addr := emitAddr
      io.cSram.write := needEmit
      io.cSram.dataIn := emitData
      io.cSram.bweb := emitBweb

      when(writeValid) {
        when(!cAsmValidReg) {
          cAsmValidReg := true.B
          cAsmAddrReg := curWordAddr
          cAsmDataReg := curWriteData
          cAsmBwebReg := curWriteBweb
        }.elsewhen(sameWord) {
          cAsmDataReg := (cAsmDataReg & curWriteBweb) | curWriteData
          cAsmBwebReg := cAsmBwebReg & curWriteBweb
        }.otherwise {
          cAsmValidReg := true.B
          cAsmAddrReg := curWordAddr
          cAsmDataReg := curWriteData
          cAsmBwebReg := curWriteBweb
        }

        when(lastElem) {
          state := sFlushC
        }.otherwise {
          colWriteReg := colWriteReg + 1.U
        }
      }.otherwise {
        state := sFlushC
      }
    }

    is(sFlushC) {
      io.cSram.enable := cAsmValidReg
      io.cSram.addr := cAsmAddrReg
      io.cSram.write := cAsmValidReg
      io.cSram.dataIn := cAsmDataReg
      io.cSram.bweb := cAsmBwebReg

      cAsmValidReg := false.B
      cAsmAddrReg := 0.U
      cAsmDataReg := 0.U
      cAsmBwebReg := Fill(sramDataWidth, 1.U(1.W))

      when(rowLast) {
        when(tileLastCol) {
          state := sDone
        }.otherwise {
          val nextTileCol = tileColIdxReg + 1.U
          tileColIdxReg := nextTileCol
          tileColsReg := tileSizeFor(mReg, nextTileCol)
          rowIdxReg := 0.U
          state := sClearPulse
        }
      }.otherwise {
        rowIdxReg := rowIdxReg + 1.U
        state := sClearPulse
      }
    }

    is(sDone) {
      state := sIdle
    }
  }

  io.busy := (state =/= sIdle) && (state =/= sDone)
  io.done := state === sDone
}

class MacArrayCtrlGene(
  val nArray: Int = 16,
  val sramDepth: Int = 2048,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(sramDepth)

  val io = IO(new Bundle {
    val opSel = Input(UInt(2.W))
    val start = Input(Bool())
    val nRows = Input(UInt(dimWidth.W))
    val mCols = Input(UInt(dimWidth.W))
    val kDim = Input(UInt(dimWidth.W))
    val alpha = Input(UInt(fpw.W))
    val baseA = Input(UInt(addrWidth.W))
    val baseB = Input(UInt(addrWidth.W))
    val baseC = Input(UInt(addrWidth.W))

    val busy = Output(Bool())
    val done = Output(Bool())

    val aSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val bSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
    val cSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))
  })

  val opSelReg = RegInit(0.U(2.W))
  val selGemmStart = io.opSel === MacArrayOp.GEMM.U
  val selMulStart = io.opSel === MacArrayOp.MUL.U
  val selAddStart = io.opSel === MacArrayOp.ADD.U

  when(io.start && !io.busy) {
    opSelReg := io.opSel
  }

  val selGemm = opSelReg === MacArrayOp.GEMM.U
  val selMul = opSelReg === MacArrayOp.MUL.U
  val selAdd = opSelReg === MacArrayOp.ADD.U

  val gemm = Module(new MacArrayGEMMCtrl(nArray, sramDepth, sramDataWidth, dimWidth, sigWidth, expWidth, ieeeCompliance, enUbrFlag))
  val mul = Module(new MacArrayMULCtrl(nArray, sramDepth, sramDataWidth, dimWidth, sigWidth, expWidth, ieeeCompliance, enUbrFlag))
  val add = Module(new MacArrayADDCtrl(nArray, sramDepth, sramDataWidth, dimWidth, sigWidth, expWidth, ieeeCompliance, enUbrFlag))

  gemm.io.start := io.start && selGemmStart
  gemm.io.nRows := io.nRows
  gemm.io.mCols := io.mCols
  gemm.io.kDim := io.kDim
  gemm.io.baseA := io.baseA
  gemm.io.baseB := io.baseB
  gemm.io.baseC := io.baseC

  mul.io.start := io.start && selMulStart
  mul.io.nRows := io.nRows
  mul.io.mCols := io.mCols
  mul.io.alpha := io.alpha
  mul.io.baseA := io.baseA
  mul.io.baseC := io.baseC

  add.io.start := io.start && selAddStart
  add.io.nRows := io.nRows
  add.io.mCols := io.mCols
  add.io.baseA := io.baseA
  add.io.baseB := io.baseB
  add.io.baseC := io.baseC

  io.busy := Mux(selGemm, gemm.io.busy, Mux(selMul, mul.io.busy, Mux(selAdd, add.io.busy, false.B)))
  io.done := Mux(selGemm, gemm.io.done, Mux(selMul, mul.io.done, Mux(selAdd, add.io.done, false.B)))

  io.aSram.enable := Mux(selGemm, gemm.io.aSram.enable, Mux(selMul, mul.io.aSram.enable, Mux(selAdd, add.io.aSram.enable, false.B)))
  io.aSram.addr := Mux(selGemm, gemm.io.aSram.addr, Mux(selMul, mul.io.aSram.addr, Mux(selAdd, add.io.aSram.addr, 0.U)))
  io.aSram.write := Mux(selGemm, gemm.io.aSram.write, Mux(selMul, mul.io.aSram.write, Mux(selAdd, add.io.aSram.write, false.B)))
  io.aSram.dataIn := Mux(selGemm, gemm.io.aSram.dataIn, Mux(selMul, mul.io.aSram.dataIn, Mux(selAdd, add.io.aSram.dataIn, 0.U)))
  io.aSram.bweb := Mux(selGemm, gemm.io.aSram.bweb, Mux(selMul, mul.io.aSram.bweb, Mux(selAdd, add.io.aSram.bweb, Fill(sramDataWidth, 1.U(1.W)))))

  io.bSram.enable := Mux(selGemm, gemm.io.bSram.enable, Mux(selAdd, add.io.bSram.enable, false.B))
  io.bSram.addr := Mux(selGemm, gemm.io.bSram.addr, Mux(selAdd, add.io.bSram.addr, 0.U))
  io.bSram.write := Mux(selGemm, gemm.io.bSram.write, Mux(selAdd, add.io.bSram.write, false.B))
  io.bSram.dataIn := Mux(selGemm, gemm.io.bSram.dataIn, Mux(selAdd, add.io.bSram.dataIn, 0.U))
  io.bSram.bweb := Mux(selGemm, gemm.io.bSram.bweb, Mux(selAdd, add.io.bSram.bweb, Fill(sramDataWidth, 1.U(1.W))))

  io.cSram.enable := Mux(selGemm, gemm.io.cSram.enable, Mux(selMul, mul.io.cSram.enable, Mux(selAdd, add.io.cSram.enable, false.B)))
  io.cSram.addr := Mux(selGemm, gemm.io.cSram.addr, Mux(selMul, mul.io.cSram.addr, Mux(selAdd, add.io.cSram.addr, 0.U)))
  io.cSram.write := Mux(selGemm, gemm.io.cSram.write, Mux(selMul, mul.io.cSram.write, Mux(selAdd, add.io.cSram.write, false.B)))
  io.cSram.dataIn := Mux(selGemm, gemm.io.cSram.dataIn, Mux(selMul, mul.io.cSram.dataIn, Mux(selAdd, add.io.cSram.dataIn, 0.U)))
  io.cSram.bweb := Mux(selGemm, gemm.io.cSram.bweb, Mux(selMul, mul.io.cSram.bweb, Mux(selAdd, add.io.cSram.bweb, Fill(sramDataWidth, 1.U(1.W)))))

  gemm.io.aSram.dataOut := io.aSram.dataOut
  mul.io.aSram.dataOut := io.aSram.dataOut
  add.io.aSram.dataOut := io.aSram.dataOut

  gemm.io.bSram.dataOut := io.bSram.dataOut
  add.io.bSram.dataOut := io.bSram.dataOut

  gemm.io.cSram.dataOut := io.cSram.dataOut
  mul.io.cSram.dataOut := io.cSram.dataOut
  add.io.cSram.dataOut := io.cSram.dataOut
}
