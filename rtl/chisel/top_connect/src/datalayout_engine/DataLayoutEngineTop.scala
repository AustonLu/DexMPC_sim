import chisel3._
import chisel3.util._

class DataLayoutEngineTopCmd(
  val inAddrWidth: Int,
  val outAddrWidth: Int,
  val dimWidth: Int,
  val reqIdWidth: Int
) extends Bundle {
  val mode = Bool()
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(inAddrWidth.W)
  val srcRows = UInt(dimWidth.W)
  val srcCols = UInt(dimWidth.W)
  val dstBase = UInt(outAddrWidth.W)
  val dstRows = UInt(dimWidth.W)
  val dstCols = UInt(dimWidth.W)
  val offsetRow = UInt(dimWidth.W)
  val offsetCol = UInt(dimWidth.W)
  val reqId = UInt(reqIdWidth.W)
}

class DataLayoutEngineTopRsp(
  val inAddrWidth: Int,
  val outAddrWidth: Int,
  val dimWidth: Int,
  val reqIdWidth: Int
) extends Bundle {
  val mode = Bool()
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(inAddrWidth.W)
  val srcRows = UInt(dimWidth.W)
  val srcCols = UInt(dimWidth.W)
  val dstBase = UInt(outAddrWidth.W)
  val dstRows = UInt(dimWidth.W)
  val dstCols = UInt(dimWidth.W)
  val offsetRow = UInt(dimWidth.W)
  val offsetCol = UInt(dimWidth.W)
  val reqId = UInt(reqIdWidth.W)
  val done = Bool()
}

class DataLayoutEngineTop(
  val numSequencers: Int = 4,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val inWordWidth: Int = 128,
  val outWordWidth: Int = 128,
  val valueWidth: Int = 16,
  val dimWidth: Int = 8,
  val reqIdWidth: Int = 8
) extends Module {
  require(numSequencers > 0, "DataLayoutEngineTop numSequencers must be > 0")
  require(inWordWidth == outWordWidth, "DataLayoutEngineTop requires inWordWidth == outWordWidth for shared SRAMs")

  private val inAddrWidth = log2Ceil(globalDepth)
  private val outAddrWidth = log2Ceil(globalDepth)
  private val globalAddrWidth = log2Ceil(globalDepth)
  private val localAddrWidth = log2Ceil(localDepth)
  private val tempAddrWidth = log2Ceil(tempDepth)
  private val seqIdWidth = math.max(1, log2Ceil(numSequencers))

  private val cmdType = new DataLayoutEngineTopCmd(inAddrWidth, outAddrWidth, dimWidth, reqIdWidth)
  private val rspType = new DataLayoutEngineTopRsp(inAddrWidth, outAddrWidth, dimWidth, reqIdWidth)

  val io = IO(new Bundle {
    val cmdReq = Vec(numSequencers, Flipped(Decoupled(cmdType)))
    val cmdRsp = Vec(numSequencers, Decoupled(rspType))

    val busy = Output(Bool())
    val idle = Output(Bool())
    val status = Output(UInt(2.W)) // 0: idle, 1: running, 2: wait response consume
    val activeSequencerValid = Output(Bool())
    val activeSequencerId = Output(UInt(seqIdWidth.W))

    val globalSram = Flipped(new SramRwIO(dataWidth = inWordWidth, addrWidth = globalAddrWidth))
    val localSram = Flipped(new SramRwIO(dataWidth = inWordWidth, addrWidth = localAddrWidth))
    val tempSram = Flipped(new SramRwIO(dataWidth = inWordWidth, addrWidth = tempAddrWidth))
  })

  val core = Module(new DataLayoutEngine(
    inAddrWidth = inAddrWidth,
    outAddrWidth = outAddrWidth,
    inWordWidth = inWordWidth,
    outWordWidth = outWordWidth,
    valueWidth = valueWidth,
    dimWidth = dimWidth
  ))

  val arb = Module(new DecoupledRRArb(cmdType, rspType, numSequencers))

  arb.io.cmdReq <> io.cmdReq
  io.cmdRsp <> arb.io.cmdRsp

  arb.io.coreBusy := core.io.busy
  arb.io.coreDone := core.io.done

  core.io.start := arb.io.start
  core.io.cfg.mode := arb.io.cmdOut.mode
  core.io.cfg.srcBase := arb.io.cmdOut.srcBase
  core.io.cfg.srcRows := arb.io.cmdOut.srcRows
  core.io.cfg.srcCols := arb.io.cmdOut.srcCols
  core.io.cfg.dstBase := arb.io.cmdOut.dstBase
  core.io.cfg.dstRows := arb.io.cmdOut.dstRows
  core.io.cfg.dstCols := arb.io.cmdOut.dstCols
  core.io.cfg.offsetRow := arb.io.cmdOut.offsetRow
  core.io.cfg.offsetCol := arb.io.cmdOut.offsetCol

  val rspBits = Wire(rspType)
  rspBits.mode := arb.io.activeCmd.mode
  rspBits.srcSramId := arb.io.activeCmd.srcSramId
  rspBits.dstSramId := arb.io.activeCmd.dstSramId
  rspBits.srcBase := arb.io.activeCmd.srcBase
  rspBits.srcRows := arb.io.activeCmd.srcRows
  rspBits.srcCols := arb.io.activeCmd.srcCols
  rspBits.dstBase := arb.io.activeCmd.dstBase
  rspBits.dstRows := arb.io.activeCmd.dstRows
  rspBits.dstCols := arb.io.activeCmd.dstCols
  rspBits.offsetRow := arb.io.activeCmd.offsetRow
  rspBits.offsetCol := arb.io.activeCmd.offsetCol
  rspBits.reqId := arb.io.activeCmd.reqId
  rspBits.done := true.B
  arb.io.rspIn := rspBits

  val srcSramIdReg = RegInit(0.U(2.W))
  val dstSramIdReg = RegInit(0.U(2.W))
  when(arb.io.start) {
    srcSramIdReg := arb.io.cmdOut.srcSramId
    dstSramIdReg := arb.io.cmdOut.dstSramId
    assert(arb.io.cmdOut.srcSramId =/= 3.U, "DataLayoutEngineTop: srcSramId=3 is reserved")
    assert(arb.io.cmdOut.dstSramId =/= 3.U, "DataLayoutEngineTop: dstSramId=3 is reserved")
  }

  val gReqSrc = (srcSramIdReg === 0.U) && core.io.src.enable
  val lReqSrc = (srcSramIdReg === 1.U) && core.io.src.enable
  val tReqSrc = (srcSramIdReg === 2.U) && core.io.src.enable

  val gReqDst = (dstSramIdReg === 0.U) && core.io.dst.enable
  val lReqDst = (dstSramIdReg === 1.U) && core.io.dst.enable
  val tReqDst = (dstSramIdReg === 2.U) && core.io.dst.enable

  assert(!(gReqSrc && gReqDst), "DataLayoutEngineTop: src/dst both target GlobalSram in same cycle")
  assert(!(lReqSrc && lReqDst), "DataLayoutEngineTop: src/dst both target LocalSram in same cycle")
  assert(!(tReqSrc && tReqDst), "DataLayoutEngineTop: src/dst both target TempSram in same cycle")

  io.globalSram.enable := false.B
  io.globalSram.addr := 0.U
  io.globalSram.write := false.B
  io.globalSram.dataIn := 0.U
  io.globalSram.bweb := Fill(inWordWidth, 1.U(1.W))

  io.localSram.enable := false.B
  io.localSram.addr := 0.U
  io.localSram.write := false.B
  io.localSram.dataIn := 0.U
  io.localSram.bweb := Fill(inWordWidth, 1.U(1.W))

  io.tempSram.enable := false.B
  io.tempSram.addr := 0.U
  io.tempSram.write := false.B
  io.tempSram.dataIn := 0.U
  io.tempSram.bweb := Fill(inWordWidth, 1.U(1.W))

  when(gReqSrc) {
    io.globalSram.enable := true.B
    io.globalSram.addr := core.io.src.addr(globalAddrWidth - 1, 0)
    io.globalSram.write := core.io.src.write
    io.globalSram.dataIn := core.io.src.dataIn
    io.globalSram.bweb := core.io.src.bweb
  }.elsewhen(gReqDst) {
    io.globalSram.enable := true.B
    io.globalSram.addr := core.io.dst.addr(globalAddrWidth - 1, 0)
    io.globalSram.write := core.io.dst.write
    io.globalSram.dataIn := core.io.dst.dataIn
    io.globalSram.bweb := core.io.dst.bweb
  }

  when(lReqSrc) {
    io.localSram.enable := true.B
    io.localSram.addr := core.io.src.addr(localAddrWidth - 1, 0)
    io.localSram.write := core.io.src.write
    io.localSram.dataIn := core.io.src.dataIn
    io.localSram.bweb := core.io.src.bweb
  }.elsewhen(lReqDst) {
    io.localSram.enable := true.B
    io.localSram.addr := core.io.dst.addr(localAddrWidth - 1, 0)
    io.localSram.write := core.io.dst.write
    io.localSram.dataIn := core.io.dst.dataIn
    io.localSram.bweb := core.io.dst.bweb
  }

  when(tReqSrc) {
    io.tempSram.enable := true.B
    io.tempSram.addr := core.io.src.addr(tempAddrWidth - 1, 0)
    io.tempSram.write := core.io.src.write
    io.tempSram.dataIn := core.io.src.dataIn
    io.tempSram.bweb := core.io.src.bweb
  }.elsewhen(tReqDst) {
    io.tempSram.enable := true.B
    io.tempSram.addr := core.io.dst.addr(tempAddrWidth - 1, 0)
    io.tempSram.write := core.io.dst.write
    io.tempSram.dataIn := core.io.dst.dataIn
    io.tempSram.bweb := core.io.dst.bweb
  }

  core.io.src.dataOut := MuxLookup(srcSramIdReg, io.globalSram.dataOut)(Seq(
    0.U -> io.globalSram.dataOut,
    1.U -> io.localSram.dataOut,
    2.U -> io.tempSram.dataOut
  ))
  core.io.dst.dataOut := MuxLookup(dstSramIdReg, io.globalSram.dataOut)(Seq(
    0.U -> io.globalSram.dataOut,
    1.U -> io.localSram.dataOut,
    2.U -> io.tempSram.dataOut
  ))

  io.busy := arb.io.busy
  io.idle := arb.io.idle
  io.status := arb.io.status
  io.activeSequencerValid := arb.io.activeSequencerValid
  io.activeSequencerId := arb.io.activeSequencerId
}
