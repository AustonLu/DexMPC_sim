import chisel3._
import chisel3.util._

class MacArrayTop(
  val nArray: Int = 16,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(globalDepth)
  private val globalAddrWidth = log2Ceil(globalDepth)
  private val localAddrWidth = log2Ceil(localDepth)
  private val tempAddrWidth = log2Ceil(tempDepth)

  val io = IO(new Bundle {
    // Operation select: 0 = GEMM, 1 = MUL, 2 = ADD
    val opSel = Input(UInt(2.W))
    val start = Input(Bool())

    // Operand dimensions
    val nRows = Input(UInt(dimWidth.W))
    val mCols = Input(UInt(dimWidth.W))
    val kDim = Input(UInt(dimWidth.W)) // only used by GEMM

    // Scalar for MUL
    val alpha = Input(UInt(fpw.W))

    // Base addresses (word address)
    val baseA = Input(UInt(addrWidth.W))
    val baseB = Input(UInt(addrWidth.W))
    val baseC = Input(UInt(addrWidth.W))

    val baseASramId = Input(UInt(2.W))
    val baseBSramId = Input(UInt(2.W))
    val baseCSramId = Input(UInt(2.W))

    val busy = Output(Bool())
    val done = Output(Bool())

    // Physical SRAM ports
    val globalSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = globalAddrWidth))
    val localSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = localAddrWidth))
    val tempSram = Flipped(new SramRwIO(dataWidth = sramDataWidth, addrWidth = tempAddrWidth))
  })

  val ctrl = Module(new MacArrayCtrlGene(nArray, globalDepth, sramDataWidth, dimWidth, sigWidth, expWidth, ieeeCompliance, enUbrFlag))

  ctrl.io.opSel := io.opSel
  ctrl.io.start := io.start
  ctrl.io.nRows := io.nRows
  ctrl.io.mCols := io.mCols
  ctrl.io.kDim := io.kDim
  ctrl.io.alpha := io.alpha
  ctrl.io.baseA := io.baseA
  ctrl.io.baseB := io.baseB
  ctrl.io.baseC := io.baseC

  io.busy := ctrl.io.busy
  io.done := ctrl.io.done

  val aSramIdReg = RegInit(0.U(2.W))
  val bSramIdReg = RegInit(0.U(2.W))
  val cSramIdReg = RegInit(0.U(2.W))
  when(io.start && !ctrl.io.busy) {
    aSramIdReg := io.baseASramId
    bSramIdReg := io.baseBSramId
    cSramIdReg := io.baseCSramId
    assert(io.baseASramId =/= 3.U, "MacArrayTop: baseASramId=3 is reserved")
    assert(io.baseBSramId =/= 3.U, "MacArrayTop: baseBSramId=3 is reserved")
    assert(io.baseCSramId =/= 3.U, "MacArrayTop: baseCSramId=3 is reserved")
  }

  val aUseGlobal = aSramIdReg === 0.U
  val aUseLocal = aSramIdReg === 1.U
  val aUseTemp = aSramIdReg === 2.U

  val bUseGlobal = bSramIdReg === 0.U
  val bUseLocal = bSramIdReg === 1.U
  val bUseTemp = bSramIdReg === 2.U

  val cUseGlobal = cSramIdReg === 0.U
  val cUseLocal = cSramIdReg === 1.U
  val cUseTemp = cSramIdReg === 2.U

  val gReqA = aUseGlobal && ctrl.io.aSram.enable
  val gReqB = bUseGlobal && ctrl.io.bSram.enable
  val gReqC = cUseGlobal && ctrl.io.cSram.enable

  val lReqA = aUseLocal && ctrl.io.aSram.enable
  val lReqB = bUseLocal && ctrl.io.bSram.enable
  val lReqC = cUseLocal && ctrl.io.cSram.enable

  val tReqA = aUseTemp && ctrl.io.aSram.enable
  val tReqB = bUseTemp && ctrl.io.bSram.enable
  val tReqC = cUseTemp && ctrl.io.cSram.enable

  io.globalSram.enable := false.B
  io.globalSram.write := false.B
  io.globalSram.addr := 0.U
  io.globalSram.dataIn := 0.U
  io.globalSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  when(gReqA) {
    io.globalSram.enable := true.B
    io.globalSram.write := ctrl.io.aSram.write
    io.globalSram.addr := ctrl.io.aSram.addr(globalAddrWidth - 1, 0)
    io.globalSram.dataIn := ctrl.io.aSram.dataIn
    io.globalSram.bweb := ctrl.io.aSram.bweb
  }.elsewhen(gReqB) {
    io.globalSram.enable := true.B
    io.globalSram.write := ctrl.io.bSram.write
    io.globalSram.addr := ctrl.io.bSram.addr(globalAddrWidth - 1, 0)
    io.globalSram.dataIn := ctrl.io.bSram.dataIn
    io.globalSram.bweb := ctrl.io.bSram.bweb
  }.elsewhen(gReqC) {
    io.globalSram.enable := true.B
    io.globalSram.write := ctrl.io.cSram.write
    io.globalSram.addr := ctrl.io.cSram.addr(globalAddrWidth - 1, 0)
    io.globalSram.dataIn := ctrl.io.cSram.dataIn
    io.globalSram.bweb := ctrl.io.cSram.bweb
  }

  io.localSram.enable := false.B
  io.localSram.write := false.B
  io.localSram.addr := 0.U
  io.localSram.dataIn := 0.U
  io.localSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  when(lReqA) {
    io.localSram.enable := true.B
    io.localSram.write := ctrl.io.aSram.write
    io.localSram.addr := ctrl.io.aSram.addr(localAddrWidth - 1, 0)
    io.localSram.dataIn := ctrl.io.aSram.dataIn
    io.localSram.bweb := ctrl.io.aSram.bweb
  }.elsewhen(lReqB) {
    io.localSram.enable := true.B
    io.localSram.write := ctrl.io.bSram.write
    io.localSram.addr := ctrl.io.bSram.addr(localAddrWidth - 1, 0)
    io.localSram.dataIn := ctrl.io.bSram.dataIn
    io.localSram.bweb := ctrl.io.bSram.bweb
  }.elsewhen(lReqC) {
    io.localSram.enable := true.B
    io.localSram.write := ctrl.io.cSram.write
    io.localSram.addr := ctrl.io.cSram.addr(localAddrWidth - 1, 0)
    io.localSram.dataIn := ctrl.io.cSram.dataIn
    io.localSram.bweb := ctrl.io.cSram.bweb
  }

  io.tempSram.enable := false.B
  io.tempSram.write := false.B
  io.tempSram.addr := 0.U
  io.tempSram.dataIn := 0.U
  io.tempSram.bweb := Fill(sramDataWidth, 1.U(1.W))

  when(tReqA) {
    io.tempSram.enable := true.B
    io.tempSram.write := ctrl.io.aSram.write
    io.tempSram.addr := ctrl.io.aSram.addr(tempAddrWidth - 1, 0)
    io.tempSram.dataIn := ctrl.io.aSram.dataIn
    io.tempSram.bweb := ctrl.io.aSram.bweb
  }.elsewhen(tReqB) {
    io.tempSram.enable := true.B
    io.tempSram.write := ctrl.io.bSram.write
    io.tempSram.addr := ctrl.io.bSram.addr(tempAddrWidth - 1, 0)
    io.tempSram.dataIn := ctrl.io.bSram.dataIn
    io.tempSram.bweb := ctrl.io.bSram.bweb
  }.elsewhen(tReqC) {
    io.tempSram.enable := true.B
    io.tempSram.write := ctrl.io.cSram.write
    io.tempSram.addr := ctrl.io.cSram.addr(tempAddrWidth - 1, 0)
    io.tempSram.dataIn := ctrl.io.cSram.dataIn
    io.tempSram.bweb := ctrl.io.cSram.bweb
  }

  ctrl.io.aSram.dataOut := MuxLookup(aSramIdReg, io.globalSram.dataOut)(Seq(
    0.U -> io.globalSram.dataOut,
    1.U -> io.localSram.dataOut,
    2.U -> io.tempSram.dataOut
  ))
  ctrl.io.bSram.dataOut := MuxLookup(bSramIdReg, io.globalSram.dataOut)(Seq(
    0.U -> io.globalSram.dataOut,
    1.U -> io.localSram.dataOut,
    2.U -> io.tempSram.dataOut
  ))
  ctrl.io.cSram.dataOut := MuxLookup(cSramIdReg, io.globalSram.dataOut)(Seq(
    0.U -> io.globalSram.dataOut,
    1.U -> io.localSram.dataOut,
    2.U -> io.tempSram.dataOut
  ))
}
