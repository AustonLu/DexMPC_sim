import chisel3._
import chisel3.util._
// NOTE: Use concrete Modules (ReduceTree, Fp16AddWrapper) so SV is emitted
// with DexMPCTop without requiring extra external files.

class ReduceTreeCoreCtrlSramIO(val dataWidth: Int, val addrWidth: Int) extends Bundle {
  val enable  = Output(Bool())
  val addr    = Output(UInt(addrWidth.W))
  val write   = Output(Bool())
  val dataIn  = Output(UInt(dataWidth.W))
  val dataOut = Input(UInt(dataWidth.W))
  val bweb    = Output(UInt(dataWidth.W))
}

class ReduceTreeCoreCtrl(
  val depth: Int = 2048,
  val sramDataWidth: Int = 256,
  val tileSize: Int = 16,
  val elemCountWidth: Int = 16,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0
) extends Module {
  require(depth > 0, "ReduceTreeCoreCtrl depth must be > 0")
  require(tileSize == 16, "ReduceTreeCoreCtrl currently supports tileSize = 16")
  require((tileSize & (tileSize - 1)) == 0, "ReduceTreeCoreCtrl tileSize must be power of 2")
  require(elemCountWidth >= log2Ceil(tileSize), "ReduceTreeCoreCtrl elemCountWidth is too small for tile index")

  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(depth)
  private val tileShift = log2Ceil(tileSize)
  private val tileElemCountWidth = log2Ceil(tileSize + 1)
  private val tileCountWidth = elemCountWidth + 1
  private val lanesPerWord = sramDataWidth / fpw
  private val wordShift = log2Ceil(lanesPerWord)
  private val wordsPerTile = if (lanesPerWord >= tileSize) 1 else 2
  private val wordCountWidth = elemCountWidth + 1

  require(sramDataWidth % fpw == 0, "ReduceTreeCoreCtrl sramDataWidth must be multiple of FP width")
  require(
    (lanesPerWord == tileSize) || (lanesPerWord * 2 == tileSize),
    "ReduceTreeCoreCtrl supports 1-word (256b) or 2-word (128b) tiles"
  )

  val io = IO(new Bundle {
    val start = Input(Bool())
    val mode = Input(UInt(1.W)) // 0: add reduce, 1: min comparator reduce
    val baseAddr = Input(UInt(addrWidth.W))
    val elemCount = Input(UInt(elemCountWidth.W))

    val resultValue = Output(UInt(fpw.W))
    val resultIndex = Output(UInt(elemCountWidth.W))
    val busy = Output(Bool())
    val done = Output(Bool())
    val resultValid = Output(Bool())
    val status = Output(UInt(2.W)) // 0: idle, 1: busy, 2: done pulse

    val sram = new ReduceTreeCoreCtrlSramIO(sramDataWidth, addrWidth)
  })

  def orderKey(x: UInt): UInt = {
    val signMask = (BigInt(1) << (fpw - 1)).U(fpw.W)
    Mux(x(fpw - 1).asBool, ~x, x ^ signMask)
  }

  val sIdle :: sRun :: sDone :: Nil = Enum(3)
  val state = RegInit(sIdle)

  val modeReg = RegInit(0.U(1.W))
  val baseAddrReg = RegInit(0.U(addrWidth.W))
  val elemCountReg = RegInit(0.U(elemCountWidth.W))
  val totalTilesReg = RegInit(0.U(tileCountWidth.W))
  val lastTileValidElemsReg = RegInit(0.U(tileElemCountWidth.W))

  val totalWordsReg = RegInit(0.U(wordCountWidth.W))
  val issueWordReg = RegInit(0.U(wordCountWidth.W))
  val pendingWordIdxReg = RegInit(0.U(wordCountWidth.W))
  val procTileReg = RegInit(0.U(tileCountWidth.W))
  val readPendingReg = RegInit(false.B)

  val tileBufferReg = Reg(Vec(2, Vec(tileSize, UInt(fpw.W))))
  val tileBufferValidReg = RegInit(VecInit(Seq.fill(2)(false.B)))
  val tileBufferElemCountReg = RegInit(VecInit(Seq.fill(2)(0.U(tileElemCountWidth.W))))

  val accValueReg = RegInit(0.U(fpw.W))
  val accIndexReg = RegInit(0.U(elemCountWidth.W))
  val hasAccReg = RegInit(false.B)

  val reduceTree = Module(new ReduceTree(tileSize, sigWidth, expWidth, ieeeCompliance))
  val tileInputs = Wire(Vec(tileSize, UInt(fpw.W)))

  val processSlot = procTileReg(0)
  val processReady = (procTileReg < totalTilesReg) && tileBufferValidReg(processSlot)
  val padValue = Mux(modeReg === 0.U, 0.U(fpw.W), "h7c00".U(fpw.W))

  for (idx <- 0 until tileSize) {
    tileInputs(idx) := padValue
    when(processReady && (idx.U < tileBufferElemCountReg(processSlot))) {
      tileInputs(idx) := tileBufferReg(processSlot)(idx)
    }
  }

  reduceTree.io.mode := modeReg
  reduceTree.io.in := tileInputs

  val tileBaseIdx = (procTileReg << tileShift)(elemCountWidth - 1, 0)
  val tileGlobalIdx = (tileBaseIdx + reduceTree.io.idx)(elemCountWidth - 1, 0)

  val accumAdder = Module(new Fp16AddWrapper(sigWidth, expWidth, ieeeCompliance))
  accumAdder.io.a := accValueReg
  accumAdder.io.b := reduceTree.io.value

  val keepCurrentMin = orderKey(accValueReg) <= orderKey(reduceTree.io.value)

  io.resultValue := accValueReg
  io.resultIndex := Mux(modeReg === 1.U, accIndexReg, 0.U(elemCountWidth.W))
  io.busy := state === sRun
  io.done := state === sDone
  io.resultValid := state === sDone
  io.status := MuxCase(
    0.U(2.W),
    Seq(
      (state === sRun) -> 1.U(2.W),
      (state === sDone) -> 2.U(2.W)
    )
  )

  io.sram.enable := false.B
  io.sram.addr := baseAddrReg
  io.sram.write := false.B
  io.sram.dataIn := 0.U(sramDataWidth.W)
  io.sram.bweb := Fill(sramDataWidth, 1.U(1.W))

  switch(state) {
    is(sIdle) {
      when(io.start) {
        val totalTilesInit = ((Cat(0.U(1.W), io.elemCount) + (tileSize - 1).U(tileCountWidth.W)) >> tileShift)
        val totalWordsInit = ((Cat(0.U(1.W), io.elemCount) + (lanesPerWord - 1).U(wordCountWidth.W)) >> wordShift)
        val tailElems = io.elemCount(tileShift - 1, 0)

        modeReg := io.mode
        baseAddrReg := io.baseAddr
        elemCountReg := io.elemCount
        totalTilesReg := totalTilesInit
        lastTileValidElemsReg := Mux(tailElems === 0.U, tileSize.U(tileElemCountWidth.W), Cat(0.U(1.W), tailElems))

        totalWordsReg := totalWordsInit
        issueWordReg := 0.U
        pendingWordIdxReg := 0.U
        procTileReg := 0.U
        readPendingReg := false.B

        tileBufferValidReg(0) := false.B
        tileBufferValidReg(1) := false.B
        tileBufferElemCountReg(0) := 0.U
        tileBufferElemCountReg(1) := 0.U

        accValueReg := 0.U
        accIndexReg := 0.U
        hasAccReg := false.B

        state := Mux(io.elemCount === 0.U, sDone, sRun)
      }
    }

    is(sRun) {
      val responseFire = readPendingReg
      val responseWordIdx = pendingWordIdxReg
      val responseTileIdx = if (wordsPerTile == 1) responseWordIdx else (responseWordIdx >> 1)
      val responseSlot = responseTileIdx(0)
      val responseWordSel = if (wordsPerTile == 1) 0.U else responseWordIdx(0)
      val isLastTile = responseTileIdx === (totalTilesReg - 1.U)
      val lastTileOneWord = lastTileValidElemsReg <= lanesPerWord.U

      when(responseFire) {
        if (wordsPerTile == 1) {
          for (idx <- 0 until tileSize) {
            tileBufferReg(responseSlot)(idx) := io.sram.dataOut((idx + 1) * fpw - 1, idx * fpw)
          }
          tileBufferValidReg(responseSlot) := true.B
          tileBufferElemCountReg(responseSlot) := Mux(
            isLastTile,
            lastTileValidElemsReg,
            tileSize.U(tileElemCountWidth.W)
          )
        } else {
          when(responseWordSel === 0.U) {
            for (idx <- 0 until lanesPerWord) {
              tileBufferReg(responseSlot)(idx) := io.sram.dataOut((idx + 1) * fpw - 1, idx * fpw)
            }
          }.otherwise {
            for (idx <- 0 until lanesPerWord) {
              tileBufferReg(responseSlot)(idx + lanesPerWord) := io.sram.dataOut((idx + 1) * fpw - 1, idx * fpw)
            }
          }

          val tileComplete = (responseWordSel === 1.U) || (isLastTile && lastTileOneWord && responseWordSel === 0.U)
          when(tileComplete) {
            tileBufferValidReg(responseSlot) := true.B
            tileBufferElemCountReg(responseSlot) := Mux(
              isLastTile,
              lastTileValidElemsReg,
              tileSize.U(tileElemCountWidth.W)
            )
          }
        }
        readPendingReg := false.B
      }

      when(processReady) {
        when(!hasAccReg) {
          hasAccReg := true.B
          accValueReg := reduceTree.io.value
          accIndexReg := tileGlobalIdx
        }.otherwise {
          when(modeReg === 0.U) {
            accValueReg := accumAdder.io.z
          }.otherwise {
            when(!keepCurrentMin) {
              accValueReg := reduceTree.io.value
              accIndexReg := tileGlobalIdx
            }
          }
        }

        tileBufferValidReg(processSlot) := false.B
        procTileReg := procTileReg + 1.U
      }

      when(issueWordReg < totalWordsReg) {
        io.sram.enable := true.B
        io.sram.addr := baseAddrReg + issueWordReg(addrWidth - 1, 0)
        io.sram.write := false.B

        readPendingReg := true.B
        pendingWordIdxReg := issueWordReg
        issueWordReg := issueWordReg + 1.U
      }

      val allWordsIssued = issueWordReg === totalWordsReg
      val allTilesProcessed = procTileReg === totalTilesReg
      val buffersEmpty = !tileBufferValidReg(0) && !tileBufferValidReg(1)
      val noReadInFlight = !readPendingReg

      when(allWordsIssued && allTilesProcessed && buffersEmpty && noReadInFlight) {
        state := sDone
      }
    }

    is(sDone) {
      state := sIdle
    }
  }
}
