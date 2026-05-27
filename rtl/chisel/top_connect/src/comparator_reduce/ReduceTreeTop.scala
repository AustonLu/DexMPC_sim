import chisel3._
import chisel3.util._

class ReduceTreeTopCmd(
  val addrWidth: Int,
  val elemCountWidth: Int,
  val reqIdWidth: Int
) extends Bundle {
  val mode = UInt(1.W) // 0: add reduce, 1: min comparator reduce
  val srcSramId = UInt(2.W)
  val baseAddr = UInt(addrWidth.W)
  val elemCount = UInt(elemCountWidth.W)
  val reqId = UInt(reqIdWidth.W)
}

class ReduceTreeTopRsp(
  val fpw: Int,
  val addrWidth: Int,
  val elemCountWidth: Int,
  val reqIdWidth: Int
) extends Bundle {
  val reqId = UInt(reqIdWidth.W)
  val mode = UInt(1.W)
  val srcSramId = UInt(2.W)
  val baseAddr = UInt(addrWidth.W)
  val elemCount = UInt(elemCountWidth.W)
  val resultValue = UInt(fpw.W)
  val resultIndex = UInt(elemCountWidth.W)
}

class ReduceTreeTop(
  val numSequencers: Int = 4,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val sramDataWidth: Int = 128,
  val tileSize: Int = 16,
  val elemCountWidth: Int = 16,
  val reqIdWidth: Int = 8,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0
) extends Module {
  require(numSequencers > 0, "ReduceTreeTop numSequencers must be > 0")

  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(globalDepth)
  private val globalAddrWidth = log2Ceil(globalDepth)
  private val localAddrWidth = log2Ceil(localDepth)
  private val tempAddrWidth = log2Ceil(tempDepth)
  private val seqIdWidth = math.max(1, log2Ceil(numSequencers))

  private val cmdType = new ReduceTreeTopCmd(addrWidth, elemCountWidth, reqIdWidth)
  private val rspType = new ReduceTreeTopRsp(fpw, addrWidth, elemCountWidth, reqIdWidth)

  val io = IO(new Bundle {
    val cmdReq = Vec(numSequencers, Flipped(Decoupled(cmdType)))
    val cmdRsp = Vec(numSequencers, Decoupled(rspType))

    val busy = Output(Bool())
    val idle = Output(Bool())
    val status = Output(UInt(2.W)) // 0: idle, 1: running, 2: wait response consume
    val activeSequencerValid = Output(Bool())
    val activeSequencerId = Output(UInt(seqIdWidth.W))

    val globalSram = new ReduceTreeCoreCtrlSramIO(sramDataWidth, globalAddrWidth)
    val localSram = new ReduceTreeCoreCtrlSramIO(sramDataWidth, localAddrWidth)
    val tempSram = new ReduceTreeCoreCtrlSramIO(sramDataWidth, tempAddrWidth)
  })

  val core = Module(
    new ReduceTreeCoreCtrl(
      depth = globalDepth,
      sramDataWidth = sramDataWidth,
      tileSize = tileSize,
      elemCountWidth = elemCountWidth,
      sigWidth = sigWidth,
      expWidth = expWidth,
      ieeeCompliance = ieeeCompliance
    )
  )

  val arb = Module(new DecoupledRRArb(cmdType, rspType, numSequencers))

  arb.io.cmdReq <> io.cmdReq
  io.cmdRsp <> arb.io.cmdRsp

  arb.io.coreBusy := core.io.busy
  arb.io.coreDone := core.io.done

  core.io.start := arb.io.start
  core.io.mode := arb.io.cmdOut.mode
  core.io.baseAddr := arb.io.cmdOut.baseAddr
  core.io.elemCount := arb.io.cmdOut.elemCount

  val rspBits = Wire(rspType)
  rspBits.reqId := arb.io.activeCmd.reqId
  rspBits.mode := arb.io.activeCmd.mode
  rspBits.srcSramId := arb.io.activeCmd.srcSramId
  rspBits.baseAddr := arb.io.activeCmd.baseAddr
  rspBits.elemCount := arb.io.activeCmd.elemCount
  rspBits.resultValue := core.io.resultValue
  rspBits.resultIndex := core.io.resultIndex
  arb.io.rspIn := rspBits

  val srcSramIdReg = RegInit(0.U(2.W))
  when(arb.io.start) {
    srcSramIdReg := arb.io.cmdOut.srcSramId
    assert(arb.io.cmdOut.srcSramId =/= 3.U, "ReduceTreeTop: srcSramId=3 is reserved")
  }

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

  val useGlobal = srcSramIdReg === 0.U
  val useLocal = srcSramIdReg === 1.U
  val useTemp = srcSramIdReg === 2.U

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

  core.io.sram.dataOut := MuxLookup(srcSramIdReg, io.globalSram.dataOut)(Seq(
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

