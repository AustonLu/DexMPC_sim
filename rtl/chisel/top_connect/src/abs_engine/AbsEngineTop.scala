import chisel3._
import chisel3.util._

class AbsEngineTopCmd(
  val addrWidth: Int,
  val dimWidth: Int,
  val reqIdWidth: Int
) extends Bundle {
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val dstBase = UInt(addrWidth.W)
  val rows = UInt(dimWidth.W)
  val cols = UInt(dimWidth.W)
  val reqId = UInt(reqIdWidth.W)
}

class AbsEngineTopRsp(
  val addrWidth: Int,
  val dimWidth: Int,
  val reqIdWidth: Int
) extends Bundle {
  val reqId = UInt(reqIdWidth.W)
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val dstBase = UInt(addrWidth.W)
  val rows = UInt(dimWidth.W)
  val cols = UInt(dimWidth.W)
  val done = Bool()
}

class AbsEngineTop(
  val numSequencers: Int = 4,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val wordWidth: Int = 128,
  val dimWidth: Int = 16,
  val reqIdWidth: Int = 8
) extends Module {
  require(numSequencers > 0, "AbsEngineTop numSequencers must be > 0")

  private val addrWidth = log2Ceil(globalDepth)
  private val globalAddrWidth = log2Ceil(globalDepth)
  private val localAddrWidth = log2Ceil(localDepth)
  private val tempAddrWidth = log2Ceil(tempDepth)
  private val seqIdWidth = math.max(1, log2Ceil(numSequencers))

  private val cmdType = new AbsEngineTopCmd(addrWidth, dimWidth, reqIdWidth)
  private val rspType = new AbsEngineTopRsp(addrWidth, dimWidth, reqIdWidth)

  val io = IO(new Bundle {
    val cmdReq = Vec(numSequencers, Flipped(Decoupled(cmdType)))
    val cmdRsp = Vec(numSequencers, Decoupled(rspType))

    val busy = Output(Bool())
    val idle = Output(Bool())
    val status = Output(UInt(2.W)) // 0: idle, 1: running, 2: wait response consume
    val activeSequencerValid = Output(Bool())
    val activeSequencerId = Output(UInt(seqIdWidth.W))

    val globalSram = Flipped(new SramRwIO(dataWidth = wordWidth, addrWidth = globalAddrWidth))
    val localSram = Flipped(new SramRwIO(dataWidth = wordWidth, addrWidth = localAddrWidth))
    val tempSram = Flipped(new SramRwIO(dataWidth = wordWidth, addrWidth = tempAddrWidth))
  })

  val core = Module(new AbsCore(depth = globalDepth, wordWidth = wordWidth, dimWidth = dimWidth))
  val arb = Module(new DecoupledRRArb(cmdType, rspType, numSequencers))

  arb.io.cmdReq <> io.cmdReq
  io.cmdRsp <> arb.io.cmdRsp

  arb.io.coreBusy := core.io.busy
  arb.io.coreDone := core.io.done

  core.io.start := arb.io.start
  core.io.srcBase := arb.io.cmdOut.srcBase
  core.io.dstBase := arb.io.cmdOut.dstBase
  core.io.rows := arb.io.cmdOut.rows
  core.io.cols := arb.io.cmdOut.cols

  val rspBits = Wire(rspType)
  rspBits.reqId := arb.io.activeCmd.reqId
  rspBits.srcSramId := arb.io.activeCmd.srcSramId
  rspBits.dstSramId := arb.io.activeCmd.dstSramId
  rspBits.srcBase := arb.io.activeCmd.srcBase
  rspBits.dstBase := arb.io.activeCmd.dstBase
  rspBits.rows := arb.io.activeCmd.rows
  rspBits.cols := arb.io.activeCmd.cols
  rspBits.done := true.B
  arb.io.rspIn := rspBits

  val srcSramIdReg = RegInit(0.U(2.W))
  val dstSramIdReg = RegInit(0.U(2.W))
  when(arb.io.start) {
    srcSramIdReg := arb.io.cmdOut.srcSramId
    dstSramIdReg := arb.io.cmdOut.dstSramId
    assert(arb.io.cmdOut.srcSramId =/= 3.U, "AbsEngineTop: srcSramId=3 is reserved")
    assert(arb.io.cmdOut.dstSramId =/= 3.U, "AbsEngineTop: dstSramId=3 is reserved")
  }

  val activeSramId = Mux(core.io.sram.write, dstSramIdReg, srcSramIdReg)

  io.globalSram.enable := false.B
  io.globalSram.addr := 0.U
  io.globalSram.write := false.B
  io.globalSram.dataIn := 0.U
  io.globalSram.bweb := Fill(wordWidth, 1.U(1.W))

  io.localSram.enable := false.B
  io.localSram.addr := 0.U
  io.localSram.write := false.B
  io.localSram.dataIn := 0.U
  io.localSram.bweb := Fill(wordWidth, 1.U(1.W))

  io.tempSram.enable := false.B
  io.tempSram.addr := 0.U
  io.tempSram.write := false.B
  io.tempSram.dataIn := 0.U
  io.tempSram.bweb := Fill(wordWidth, 1.U(1.W))

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

  core.io.sram.dataOut := MuxLookup(activeSramId, io.globalSram.dataOut)(Seq(
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
