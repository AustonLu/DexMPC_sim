import chisel3._
import chisel3.util._

class DataLayoutEngineConfig(
  val inAddrWidth: Int,
  val outAddrWidth: Int,
  val dimWidth: Int
) extends Bundle {
  val mode      = Bool()
  val srcBase   = UInt(inAddrWidth.W)
  val srcRows   = UInt(dimWidth.W)
  val srcCols   = UInt(dimWidth.W)
  val dstBase   = UInt(outAddrWidth.W)
  val dstRows   = UInt(dimWidth.W)
  val dstCols   = UInt(dimWidth.W)
  val offsetRow = UInt(dimWidth.W)
  val offsetCol = UInt(dimWidth.W)
}

class DataLayoutEngine(
  val inAddrWidth: Int = 11,
  val outAddrWidth: Int = 11,
  val inWordWidth: Int = 256,
  val outWordWidth: Int = 256,
  val valueWidth: Int = 16,
  val dimWidth: Int = 8
) extends Module {
  require(inWordWidth > 0, "inWordWidth must be > 0")
  require(outWordWidth > 0, "outWordWidth must be > 0")
  require(valueWidth > 0, "valueWidth must be > 0")
  require(inWordWidth % valueWidth == 0, s"inWordWidth ($inWordWidth) must be divisible by valueWidth ($valueWidth)")
  require(outWordWidth % valueWidth == 0, s"outWordWidth ($outWordWidth) must be divisible by valueWidth ($valueWidth)")

  private val inLanes = inWordWidth / valueWidth
  private val outLanes = outWordWidth / valueWidth
  private val srcLaneWidth = math.max(1, log2Ceil(inLanes))
  private val dstLaneWidth = math.max(1, log2Ceil(outLanes))
  private val elemCountWidth = dimWidth * 2 + 2

  private val modeTranspose = false.B
  private val modeAssemble = true.B

  val io = IO(new Bundle {
    val start = Input(Bool())
    val cfg = Input(new DataLayoutEngineConfig(inAddrWidth = inAddrWidth, outAddrWidth = outAddrWidth, dimWidth = dimWidth))
    val busy = Output(Bool())
    val done = Output(Bool())
    val error = Output(Bool())
    val src = Flipped(new SramRwIO(dataWidth = inWordWidth, addrWidth = inAddrWidth))
    val dst = Flipped(new SramRwIO(dataWidth = outWordWidth, addrWidth = outAddrWidth))
  })

  val sIdle :: sNeedSrcWord :: sWaitSrcWord :: sWriteDst :: sFlushAssembleBuf :: Nil = Enum(5)
  val state = RegInit(sIdle)

  val modeReg = RegInit(false.B)
  val srcBaseReg = RegInit(0.U(inAddrWidth.W))
  val srcRowsReg = RegInit(0.U(dimWidth.W))
  val srcColsReg = RegInit(0.U(dimWidth.W))
  val dstBaseReg = RegInit(0.U(outAddrWidth.W))
  val dstRowsReg = RegInit(0.U(dimWidth.W))
  val dstColsReg = RegInit(0.U(dimWidth.W))
  val offsetRowReg = RegInit(0.U(dimWidth.W))
  val offsetColReg = RegInit(0.U(dimWidth.W))

  val srcRowReg = RegInit(0.U(dimWidth.W))
  val srcColReg = RegInit(0.U(dimWidth.W))
  val srcWordOffsetReg = RegInit(0.U(elemCountWidth.W))
  val srcLaneReg = RegInit(0.U(srcLaneWidth.W))
  val srcWordValidReg = RegInit(false.B)
  val srcWordDataReg = RegInit(0.U(inWordWidth.W))
  val asmBufValidReg = RegInit(false.B)
  val asmBufAddrReg = RegInit(0.U(outAddrWidth.W))
  val asmBufDataReg = RegInit(0.U(outWordWidth.W))
  val asmBufBwebReg = RegInit(0.U(outWordWidth.W))

  val donePulseReg = RegInit(false.B)
  val errorReg = RegInit(false.B)

  private def extractLane(word: UInt, lane: UInt, laneCount: Int): UInt = {
    Mux1H((0 until laneCount).map(i => (lane === i.U) -> word((i + 1) * valueWidth - 1, i * valueWidth)))
  }

  private def buildLaneWriteData(lane: UInt, laneValue: UInt): UInt = {
    VecInit((0 until outLanes).map(i => Mux(lane === i.U, laneValue, 0.U(valueWidth.W)))).asUInt
  }

  private def buildLaneWriteBweb(lane: UInt): UInt = {
    VecInit((0 until outLanes).map(i => Mux(lane === i.U, 0.U(valueWidth.W), Fill(valueWidth, 1.U(1.W))))).asUInt
  }

  private def advanceSourceCursor(): Unit = {
    when(srcColReg === (srcColsReg - 1.U)) {
      srcColReg := 0.U
      srcRowReg := srcRowReg + 1.U
    }.otherwise {
      srcColReg := srcColReg + 1.U
    }

    when(srcLaneReg === (inLanes - 1).U) {
      srcLaneReg := 0.U
      srcWordOffsetReg := srcWordOffsetReg + 1.U
      srcWordValidReg := false.B
    }.otherwise {
      srcLaneReg := srcLaneReg + 1.U
    }

    state := sNeedSrcWord
  }

  io.src.enable := false.B
  io.src.addr := 0.U
  io.src.write := false.B
  io.src.dataIn := 0.U
  io.src.bweb := Fill(inWordWidth, 1.U(1.W))

  io.dst.enable := false.B
  io.dst.addr := 0.U
  io.dst.write := false.B
  io.dst.dataIn := 0.U
  io.dst.bweb := Fill(outWordWidth, 1.U(1.W))

  donePulseReg := false.B

  val transposeFits = (io.cfg.srcCols <= io.cfg.dstRows) && (io.cfg.srcRows <= io.cfg.dstCols)
  val assembleFits = (io.cfg.offsetRow +& io.cfg.srcRows <= io.cfg.dstRows) && (io.cfg.offsetCol +& io.cfg.srcCols <= io.cfg.dstCols)
  val cfgValid = Mux(io.cfg.mode === modeAssemble, assembleFits, transposeFits)
  val emptyInput = (io.cfg.srcRows === 0.U) || (io.cfg.srcCols === 0.U)

  switch(state) {
    is(sIdle) {
      when(io.start) {
        modeReg := io.cfg.mode
        srcBaseReg := io.cfg.srcBase
        srcRowsReg := io.cfg.srcRows
        srcColsReg := io.cfg.srcCols
        dstBaseReg := io.cfg.dstBase
        dstRowsReg := io.cfg.dstRows
        dstColsReg := io.cfg.dstCols
        offsetRowReg := io.cfg.offsetRow
        offsetColReg := io.cfg.offsetCol

        srcRowReg := 0.U
        srcColReg := 0.U
        srcWordOffsetReg := 0.U
        srcLaneReg := 0.U
        srcWordValidReg := false.B
        srcWordDataReg := 0.U
        asmBufValidReg := false.B
        asmBufAddrReg := 0.U
        asmBufDataReg := 0.U
        asmBufBwebReg := Fill(outWordWidth, 1.U(1.W))

        errorReg := false.B

        when(!cfgValid) {
          errorReg := true.B
          donePulseReg := true.B
        }.elsewhen(emptyInput) {
          donePulseReg := true.B
        }.otherwise {
          state := sNeedSrcWord
        }
      }
    }

    is(sNeedSrcWord) {
      when(srcWordValidReg) {
        state := sWriteDst
      }.otherwise {
        io.src.enable := true.B
        io.src.addr := (srcBaseReg + srcWordOffsetReg)(inAddrWidth - 1, 0)
        io.src.write := false.B
        io.src.bweb := Fill(inWordWidth, 1.U(1.W))
        state := sWaitSrcWord
      }
    }

    is(sWaitSrcWord) {
      srcWordDataReg := io.src.dataOut
      srcWordValidReg := true.B
      state := sWriteDst
    }

    is(sWriteDst) {
      val mappedRow = Wire(UInt((dimWidth + 1).W))
      val mappedCol = Wire(UInt((dimWidth + 1).W))
      mappedRow := Mux(modeReg === modeAssemble, srcRowReg +& offsetRowReg, srcColReg)
      mappedCol := Mux(modeReg === modeAssemble, srcColReg +& offsetColReg, srcRowReg)

      val dstLinear = mappedRow * dstColsReg + mappedCol
      val dstWordOffset = dstLinear / outLanes.U
      val dstLane = dstLinear % outLanes.U
      val dstLaneTrim = dstLane(dstLaneWidth - 1, 0)
      val srcLaneValue = extractLane(srcWordDataReg, srcLaneReg, inLanes)
      val curDstAddr = (dstBaseReg + dstWordOffset)(outAddrWidth - 1, 0)
      val curWriteData = buildLaneWriteData(dstLaneTrim, srcLaneValue)
      val curWriteBweb = buildLaneWriteBweb(dstLaneTrim)

      val lastElem = (srcRowReg === (srcRowsReg - 1.U)) && (srcColReg === (srcColsReg - 1.U))
      when(modeReg === modeAssemble) {
        when(!asmBufValidReg) {
          asmBufValidReg := true.B
          asmBufAddrReg := curDstAddr
          asmBufDataReg := curWriteData
          asmBufBwebReg := curWriteBweb
          when(lastElem) {
            srcWordValidReg := false.B
            state := sFlushAssembleBuf
          }.otherwise {
            advanceSourceCursor()
          }
        }.elsewhen(asmBufAddrReg === curDstAddr) {
          asmBufDataReg := (asmBufDataReg & curWriteBweb) | curWriteData
          asmBufBwebReg := asmBufBwebReg & curWriteBweb
          when(lastElem) {
            srcWordValidReg := false.B
            state := sFlushAssembleBuf
          }.otherwise {
            advanceSourceCursor()
          }
        }.otherwise {
          io.dst.enable := true.B
          io.dst.addr := asmBufAddrReg
          io.dst.write := true.B
          io.dst.dataIn := asmBufDataReg
          io.dst.bweb := asmBufBwebReg

          asmBufValidReg := true.B
          asmBufAddrReg := curDstAddr
          asmBufDataReg := curWriteData
          asmBufBwebReg := curWriteBweb
          when(lastElem) {
            srcWordValidReg := false.B
            state := sFlushAssembleBuf
          }.otherwise {
            advanceSourceCursor()
          }
        }
      }.otherwise {
        io.dst.enable := true.B
        io.dst.addr := curDstAddr
        io.dst.write := true.B
        io.dst.dataIn := curWriteData
        io.dst.bweb := curWriteBweb
        when(lastElem) {
          srcWordValidReg := false.B
          donePulseReg := true.B
          state := sIdle
        }.otherwise {
          advanceSourceCursor()
        }
      }
    }

    is(sFlushAssembleBuf) {
      io.dst.enable := true.B
      io.dst.addr := asmBufAddrReg
      io.dst.write := true.B
      io.dst.dataIn := asmBufDataReg
      io.dst.bweb := asmBufBwebReg
      asmBufValidReg := false.B
      asmBufDataReg := 0.U
      asmBufBwebReg := Fill(outWordWidth, 1.U(1.W))
      donePulseReg := true.B
      state := sIdle
    }
  }

  io.busy := state =/= sIdle
  io.done := donePulseReg
  io.error := errorReg
}
