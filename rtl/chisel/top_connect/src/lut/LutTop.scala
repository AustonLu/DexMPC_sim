import chisel3._
import chisel3.util._

object LutFuncSel {
  val trig: UInt = 0.U(2.W)
  val softplus: UInt = 1.U(2.W)
}

object LutTrigSel {
  val sin: UInt = 0.U(2.W)
  val cos: UInt = 1.U(2.W)
}

class LutTopCmd(val addrWidth: Int, val dimWidth: Int) extends Bundle {
  val funcSel: UInt = UInt(2.W)
  val trigSel: UInt = UInt(2.W)
  val srcSramId: UInt = UInt(2.W)
  val dstSramId: UInt = UInt(2.W)
  val srcBase: UInt = UInt(addrWidth.W)
  val dstBase: UInt = UInt(addrWidth.W)
  val rows: UInt = UInt(dimWidth.W)
  val cols: UInt = UInt(dimWidth.W)
}

class LutTopRsp extends Bundle {
  val done: Bool = Bool()
}

class LutCore(
  val sramDepth: Int = 2048,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 8
) extends Module {
  require(sramDepth > 0, "LutCore sramDepth must be > 0")
  require(sramDataWidth > 0, "LutCore sramDataWidth must be > 0")

  private val addrWidth = log2Ceil(sramDepth)
  private val elemWidth = 16
  require(sramDataWidth % elemWidth == 0, "LutCore sramDataWidth must be multiple of element width")

  private val lanesPerWord = sramDataWidth / elemWidth
  private val laneWidth = math.max(1, log2Ceil(lanesPerWord))
  private val takeWidth = math.max(1, log2Ceil(lanesPerWord + 1))
  private val elemCountWidth = dimWidth * 2
  private val laneShift = log2Ceil(lanesPerWord)

  val io = IO(new Bundle {
    val start = Input(Bool())
    val cfg = Input(new LutTopCmd(addrWidth, dimWidth))
    val busy = Output(Bool())
    val done = Output(Bool())

    val sram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = addrWidth))

    // External LUT SRAM ports
    val trigSinEvenSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val trigSinOddSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val trigCosEvenSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val trigCosOddSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val softplusEvenSram = Flipped(new SramRwIO(dataWidth = 32, addrWidth = log2Ceil(256)))
    val softplusOddSram = Flipped(new SramRwIO(dataWidth = 32, addrWidth = log2Ceil(256)))
  })

  private def extractLane(word: UInt, lane: UInt): UInt = {
    Mux1H((0 until lanesPerWord).map(i => (lane === i.U) -> word((i + 1) * elemWidth - 1, i * elemWidth)))
  }

  private def buildLaneWriteBweb(lane: UInt): UInt = {
    VecInit((0 until lanesPerWord).map(i => Mux(lane === i.U, 0.U(elemWidth.W), Fill(elemWidth, 1.U(1.W))))).asUInt
  }

  val trig = Module(new TrigLut(useBlackBox = true))
  val softplus = Module(new SoftplusLut(useBlackBox = true))

  trig.io.sinEvenSram <> io.trigSinEvenSram
  trig.io.sinOddSram <> io.trigSinOddSram
  trig.io.cosEvenSram <> io.trigCosEvenSram
  trig.io.cosOddSram <> io.trigCosOddSram

  softplus.io.evenSram <> io.softplusEvenSram
  softplus.io.oddSram <> io.softplusOddSram

  // Defaults
  io.sram.enable := false.B
  io.sram.addr := 0.U
  io.sram.write := false.B
  io.sram.dataIn := 0.U
  io.sram.bweb := Fill(sramDataWidth, 1.U(1.W))

  val rowsReg = RegInit(0.U(dimWidth.W))
  val colsReg = RegInit(0.U(dimWidth.W))
  val totalElemsReg = RegInit(0.U(elemCountWidth.W))
  val readElemIndexReg = RegInit(0.U(elemCountWidth.W))
  val writeElemIndexReg = RegInit(0.U(elemCountWidth.W))

  val srcBaseReg = RegInit(0.U(addrWidth.W))
  val dstBaseReg = RegInit(0.U(addrWidth.W))
  val funcSelReg = RegInit(0.U(2.W))
  val trigSelReg = RegInit(0.U(2.W))

  val running = RegInit(false.B)
  val doneReg = RegInit(false.B)
  val computeActive = RegInit(false.B)

  val curWordOffsetReg = RegInit(0.U(addrWidth.W))
  val lanesThisWordReg = RegInit(0.U(takeWidth.W))

  val inWordReg = RegInit(0.U(sramDataWidth.W))
  val outWordVec = RegInit(VecInit(Seq.fill(lanesPerWord)(0.U(elemWidth.W))))
  val outBwebReg = RegInit(0.U(sramDataWidth.W))

  val laneIssueCountReg = RegInit(0.U(takeWidth.W))
  val laneDoneCountReg = RegInit(0.U(takeWidth.W))
  val laneReqValidReg = RegInit(false.B)
  val laneReqLaneReg = RegInit(0.U(laneWidth.W))

  val readPendingReg = RegInit(false.B)
  val readPendWordOffsetReg = RegInit(0.U(addrWidth.W))
  val readPendLanesReg = RegInit(0.U(takeWidth.W))

  val prefetchValidReg = RegInit(false.B)
  val prefetchWordReg = RegInit(0.U(sramDataWidth.W))
  val prefetchWordOffsetReg = RegInit(0.U(addrWidth.W))
  val prefetchLanesReg = RegInit(0.U(takeWidth.W))

  val wbValidReg = RegInit(false.B)
  val wbWordReg = RegInit(0.U(sramDataWidth.W))
  val wbBwebReg = RegInit(0.U(sramDataWidth.W))
  val wbWordOffsetReg = RegInit(0.U(addrWidth.W))
  val wbLanesReg = RegInit(0.U(takeWidth.W))

  val lutIn = Wire(UInt(elemWidth.W))
  val lutOut = Wire(UInt(elemWidth.W))
  val emptyWordVec = VecInit(Seq.fill(lanesPerWord)(0.U(elemWidth.W)))
  val fullWordBweb = Fill(sramDataWidth, 1.U(1.W))

  val trigOut = Mux(trigSelReg === LutTrigSel.cos, trig.io.cos, trig.io.sin)
  val softOut = softplus.io.out
  val trigSelected = funcSelReg === LutFuncSel.trig
  val lutBusy = Mux(trigSelected, trig.io.busy, softplus.io.busy)
  val lutDone = Mux(trigSelected, trig.io.done, softplus.io.done)

  lutOut := Mux(funcSelReg === LutFuncSel.trig, trigOut, softOut)

  lutIn := 0.U
  trig.io.in := lutIn
  trig.io.start := false.B
  softplus.io.in := lutIn
  softplus.io.start := false.B

  doneReg := false.B

  when(io.start && !running) {
    rowsReg := io.cfg.rows
    colsReg := io.cfg.cols
    val total = io.cfg.rows * io.cfg.cols
    totalElemsReg := total
    readElemIndexReg := 0.U
    writeElemIndexReg := 0.U
    srcBaseReg := io.cfg.srcBase
    dstBaseReg := io.cfg.dstBase
    funcSelReg := io.cfg.funcSel
    trigSelReg := io.cfg.trigSel

    readPendingReg := false.B
    prefetchValidReg := false.B
    wbValidReg := false.B
    computeActive := false.B

    curWordOffsetReg := 0.U
    lanesThisWordReg := 0.U
    inWordReg := 0.U
    outWordVec := emptyWordVec
    outBwebReg := fullWordBweb
    laneIssueCountReg := 0.U
    laneDoneCountReg := 0.U
    laneReqValidReg := false.B
    laneReqLaneReg := 0.U

    when(total === 0.U) {
      running := false.B
      doneReg := true.B
    }.otherwise {
      running := true.B
    }
  }

  val willPromotePrefetch = !computeActive && prefetchValidReg

  when(running) {
    when(readPendingReg) {
      when(computeActive || willPromotePrefetch) {
        prefetchWordReg := io.sram.dataOut
        prefetchWordOffsetReg := readPendWordOffsetReg
        prefetchLanesReg := readPendLanesReg
        prefetchValidReg := true.B
      }.otherwise {
        inWordReg := io.sram.dataOut
        curWordOffsetReg := readPendWordOffsetReg
        lanesThisWordReg := readPendLanesReg

        outWordVec := emptyWordVec
        outBwebReg := fullWordBweb
        laneIssueCountReg := 0.U
        laneDoneCountReg := 0.U
        laneReqValidReg := false.B
        laneReqLaneReg := 0.U
        computeActive := true.B
      }
      readPendingReg := false.B
    }

    when(willPromotePrefetch) {
      inWordReg := prefetchWordReg
      curWordOffsetReg := prefetchWordOffsetReg
      lanesThisWordReg := prefetchLanesReg

      outWordVec := emptyWordVec
      outBwebReg := fullWordBweb
      laneIssueCountReg := 0.U
      laneDoneCountReg := 0.U
      laneReqValidReg := false.B
      laneReqLaneReg := 0.U
      computeActive := true.B

      prefetchValidReg := false.B
    }

    val remainingElems = totalElemsReg - readElemIndexReg
    val readLanes = Mux(remainingElems >= lanesPerWord.U, lanesPerWord.U(elemCountWidth.W), remainingElems)
    val readWordOffset = (readElemIndexReg >> laneShift)(addrWidth - 1, 0)
    val canRead = (readElemIndexReg < totalElemsReg) && !readPendingReg && !(computeActive && prefetchValidReg)

    when(wbValidReg) {
      io.sram.enable := true.B
      io.sram.write := true.B
      io.sram.addr := dstBaseReg + wbWordOffsetReg
      io.sram.dataIn := wbWordReg
      io.sram.bweb := wbBwebReg

      wbValidReg := false.B
      writeElemIndexReg := writeElemIndexReg + wbLanesReg
    }.elsewhen(canRead) {
      io.sram.enable := true.B
      io.sram.write := false.B
      io.sram.addr := srcBaseReg + readWordOffset
      io.sram.dataIn := 0.U
      io.sram.bweb := fullWordBweb

      readPendingReg := true.B
      readPendWordOffsetReg := readWordOffset
      readPendLanesReg := readLanes(takeWidth - 1, 0)
      readElemIndexReg := readElemIndexReg + readLanes
    }

    when(computeActive) {
      val canLaunchLane = (laneIssueCountReg < lanesThisWordReg) && !laneReqValidReg && !lutBusy
      val curLane = laneIssueCountReg(laneWidth - 1, 0)
      val outWordVecNext = Wire(Vec(lanesPerWord, UInt(elemWidth.W)))
      val outBwebNext = Wire(UInt(sramDataWidth.W))

      outWordVecNext := outWordVec
      outBwebNext := outBwebReg

      when(laneReqValidReg) {
        when(lutDone) {
          outWordVecNext(laneReqLaneReg) := lutOut
          outBwebNext := outBwebReg & buildLaneWriteBweb(laneReqLaneReg)
          laneDoneCountReg := laneDoneCountReg + 1.U
          laneReqValidReg := false.B

          when((laneDoneCountReg + 1.U) === lanesThisWordReg) {
            when(!wbValidReg) {
              wbValidReg := true.B
              wbWordReg := outWordVecNext.asUInt
              wbBwebReg := outBwebNext
              wbWordOffsetReg := curWordOffsetReg
              wbLanesReg := lanesThisWordReg
              computeActive := false.B
            }
          }
        }
      }.otherwise {
        when(canLaunchLane) {
          lutIn := extractLane(inWordReg, curLane)
          when(trigSelected) {
            trig.io.start := true.B
          }.otherwise {
            softplus.io.start := true.B
          }
          laneReqValidReg := true.B
          laneReqLaneReg := curLane
          laneIssueCountReg := laneIssueCountReg + 1.U
        }
      }

      when(!laneReqValidReg && (laneDoneCountReg === lanesThisWordReg) && !wbValidReg) {
        wbValidReg := true.B
        wbWordReg := outWordVec.asUInt
        wbBwebReg := outBwebReg
        wbWordOffsetReg := curWordOffsetReg
        wbLanesReg := lanesThisWordReg
        computeActive := false.B
      }

      outWordVec := outWordVecNext
      outBwebReg := outBwebNext
    }

    when(
      (readElemIndexReg === totalElemsReg) &&
        (writeElemIndexReg === totalElemsReg) &&
        !computeActive && !prefetchValidReg && !readPendingReg && !wbValidReg
    ) {
      running := false.B
      doneReg := true.B
    }
  }

  io.busy := running
  io.done := doneReg
}

class LutTop(
  val numSequencers: Int = 4,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 8
) extends Module {
  require(numSequencers > 0, "LutTop numSequencers must be > 0")

  private val addrWidth = log2Ceil(globalDepth)
  private val globalAddrWidth = log2Ceil(globalDepth)
  private val localAddrWidth = log2Ceil(localDepth)
  private val tempAddrWidth = log2Ceil(tempDepth)
  private val seqIdWidth = math.max(1, log2Ceil(numSequencers))

  private val cmdType = new LutTopCmd(addrWidth, dimWidth)
  private val rspType = new LutTopRsp

  val io = IO(new Bundle {
    val cmdReq = Vec(numSequencers, Flipped(Decoupled(cmdType)))
    val cmdRsp = Vec(numSequencers, Decoupled(rspType))

    val busy = Output(Bool())
    val idle = Output(Bool())
    val status = Output(UInt(2.W))
    val activeSequencerValid = Output(Bool())
    val activeSequencerId = Output(UInt(seqIdWidth.W))

    val globalSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = globalAddrWidth))
    val localSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = localAddrWidth))
    val tempSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = tempAddrWidth))

    // External LUT SRAM ports
    val trigSinEvenSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val trigSinOddSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val trigCosEvenSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val trigCosOddSram = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
    val softplusEvenSram = Flipped(new SramRwIO(dataWidth = 32, addrWidth = log2Ceil(256)))
    val softplusOddSram = Flipped(new SramRwIO(dataWidth = 32, addrWidth = log2Ceil(256)))
  })

  val core = Module(new LutCore(globalDepth, sramDataWidth, dimWidth))
  val arb = Module(new DecoupledRRArb(cmdType, rspType, numSequencers))

  arb.io.cmdReq <> io.cmdReq
  io.cmdRsp <> arb.io.cmdRsp

  arb.io.coreBusy := core.io.busy
  arb.io.coreDone := core.io.done

  core.io.start := arb.io.start
  core.io.cfg := arb.io.cmdOut

  val rspBits = Wire(rspType)
  rspBits.done := true.B
  arb.io.rspIn := rspBits

  val srcSramIdReg = RegInit(0.U(2.W))
  val dstSramIdReg = RegInit(0.U(2.W))
  val readSramIdReg = RegInit(0.U(2.W))
  when(arb.io.start) {
    srcSramIdReg := arb.io.cmdOut.srcSramId
    dstSramIdReg := arb.io.cmdOut.dstSramId
    assert(arb.io.cmdOut.srcSramId =/= 3.U, "LutTop: srcSramId=3 is reserved")
    assert(arb.io.cmdOut.dstSramId =/= 3.U, "LutTop: dstSramId=3 is reserved")
  }

  when(core.io.sram.enable && !core.io.sram.write) {
    readSramIdReg := srcSramIdReg
  }

  val activeSramId = Mux(core.io.sram.write, dstSramIdReg, srcSramIdReg)

  io.globalSram.enable := false.B
  io.globalSram.addr := 0.U
  io.globalSram.write := false.B
  io.globalSram.dataIn := 0.U
  io.globalSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.localSram.enable := false.B
  io.localSram.addr := 0.U
  io.localSram.write := false.B
  io.localSram.dataIn := 0.U
  io.localSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  io.tempSram.enable := false.B
  io.tempSram.addr := 0.U
  io.tempSram.write := false.B
  io.tempSram.dataIn := 0.U
  io.tempSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  val useGlobal = activeSramId === 0.U
  val useLocal = activeSramId === 1.U
  val useTemp = activeSramId === 2.U

  when(core.io.sram.enable && useGlobal) {
    io.globalSram.enable := core.io.sram.enable
    io.globalSram.addr := core.io.sram.addr(globalAddrWidth - 1, 0)
    io.globalSram.write := core.io.sram.write
    io.globalSram.dataIn := core.io.sram.dataIn
    io.globalSram.bweb := core.io.sram.bweb
  }

  when(core.io.sram.enable && useLocal) {
    io.localSram.enable := core.io.sram.enable
    io.localSram.addr := core.io.sram.addr(localAddrWidth - 1, 0)
    io.localSram.write := core.io.sram.write
    io.localSram.dataIn := core.io.sram.dataIn
    io.localSram.bweb := core.io.sram.bweb
  }

  when(core.io.sram.enable && useTemp) {
    io.tempSram.enable := core.io.sram.enable
    io.tempSram.addr := core.io.sram.addr(tempAddrWidth - 1, 0)
    io.tempSram.write := core.io.sram.write
    io.tempSram.dataIn := core.io.sram.dataIn
    io.tempSram.bweb := core.io.sram.bweb
  }

  core.io.sram.dataOut := MuxLookup(readSramIdReg, io.globalSram.dataOut)(Seq(
    0.U -> io.globalSram.dataOut,
    1.U -> io.localSram.dataOut,
    2.U -> io.tempSram.dataOut
  ))

  core.io.trigSinEvenSram <> io.trigSinEvenSram
  core.io.trigSinOddSram <> io.trigSinOddSram
  core.io.trigCosEvenSram <> io.trigCosEvenSram
  core.io.trigCosOddSram <> io.trigCosOddSram
  core.io.softplusEvenSram <> io.softplusEvenSram
  core.io.softplusOddSram <> io.softplusOddSram

  io.busy := arb.io.busy
  io.idle := arb.io.idle
  io.status := arb.io.status
  io.activeSequencerValid := arb.io.activeSequencerValid
  io.activeSequencerId := arb.io.activeSequencerId
}
