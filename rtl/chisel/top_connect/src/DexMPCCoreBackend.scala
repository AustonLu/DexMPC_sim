import chisel3._
import chisel3.util._
import chipmunk._

class DexMPCCoreConfigIO(val numCores: Int = 4) extends Bundle {
  val in = new Bundle {
    val cmdWord = Input(Vec(numCores, Vec(3, UInt(32.W))))
    val cmdCtrl = Input(Vec(numCores, UInt(32.W)))
    val cycleRdAddr = Input(Vec(numCores, UInt(32.W)))
    val spareIn0 = Input(UInt(32.W))
    val spareIn1 = Input(UInt(32.W))
  }

  val out = new Bundle {
    val cmdStatus = Output(Vec(numCores, UInt(32.W)))
    val doneCount = Output(Vec(numCores, UInt(32.W)))
    val lastDone = Output(Vec(numCores, UInt(32.W)))
    val lastDoneCycle = Output(Vec(numCores, UInt(32.W)))
    val cycleRdData = Output(Vec(numCores, UInt(32.W)))
    val addReduceReg = Output(Vec(numCores, UInt(32.W)))
    val cmpReduceReg0 = Output(Vec(numCores, UInt(32.W)))
    val cmpReduceReg1 = Output(Vec(numCores, UInt(32.W)))
    val engineStatus = Output(UInt(32.W))
    val done_signal = Output(UInt(32.W))
    val spareOut1 = Output(UInt(32.W))
  }
}

class DexMPCCoreBackend(
  val numCores: Int = 4,
  val fifoDepth: Int = 32,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val reqIdWidth: Int = 12,
  val elemCountWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  val io = IO(new Bundle {
    // Config input (packed)
    val config = new DexMPCCoreConfigIO(numCores = numCores)

    val allDoneReg = Output(UInt(32.W))

    // External buffer access
    val Buffer_exts = Slave(new BufferAccessIO(dataWidth = 128, addrWidth = 4 + 11))
  })

  val coreTop = Module(new DexMPCCoreTop(
    numCores = numCores,
    fifoDepth = fifoDepth,
    globalDepth = globalDepth,
    localDepth = localDepth,
    tempDepth = tempDepth,
    sramDataWidth = sramDataWidth,
    dimWidth = dimWidth,
    reqIdWidth = reqIdWidth,
    elemCountWidth = elemCountWidth,
    sigWidth = sigWidth,
    expWidth = expWidth,
    ieeeCompliance = ieeeCompliance,
    enUbrFlag = enUbrFlag
  ))

  coreTop.io.cmdWord := io.config.in.cmdWord
  coreTop.io.cmdCtrl := io.config.in.cmdCtrl
  coreTop.io.cycleRdAddr := io.config.in.cycleRdAddr
  coreTop.io.spareIn0 := io.config.in.spareIn0
  coreTop.io.spareIn1 := io.config.in.spareIn1

  io.config.out.cmdStatus := coreTop.io.cmdStatus
  io.config.out.doneCount := coreTop.io.doneCount
  io.config.out.lastDone := coreTop.io.lastDone
  io.config.out.lastDoneCycle := coreTop.io.lastDoneCycle
  io.config.out.cycleRdData := coreTop.io.cycleRdData
  io.config.out.addReduceReg := coreTop.io.addReduceReg
  io.config.out.cmpReduceReg0 := coreTop.io.cmpReduceReg0
  io.config.out.cmpReduceReg1 := coreTop.io.cmpReduceReg1
  io.config.out.engineStatus := coreTop.io.engineStatus
  io.config.out.done_signal := coreTop.io.done_signal
  io.config.out.spareOut1 := coreTop.io.spareOut1
  io.allDoneReg := coreTop.io.allDoneReg

  coreTop.io.Buffer_exts.address := io.Buffer_exts.address
  coreTop.io.Buffer_exts.enable := io.Buffer_exts.enable
  coreTop.io.Buffer_exts.isWrite := io.Buffer_exts.isWrite
  coreTop.io.Buffer_exts.writeData := io.Buffer_exts.writeData
  coreTop.io.Buffer_exts.bweb := io.Buffer_exts.bweb
  io.Buffer_exts.readData := coreTop.io.Buffer_exts.readData
}
