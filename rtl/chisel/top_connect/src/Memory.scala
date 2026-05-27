import chisel3._
import chisel3.util._
import chipmunk._

// External buffer access (reference: gaura-chip-main/hw/topConnect/src/Buffer.scala)
class BufferAccessIO(dataWidth: Int, addrWidth: Int) extends Bundle with IsMasterSlave {
  val address   = Input(UInt(addrWidth.W))
  val enable    = Input(Bool())
  val isWrite   = Input(Bool())
  val readData  = Output(UInt(dataWidth.W))
  val writeData = Input(UInt(dataWidth.W))

  val bweb      = Input(UInt(dataWidth.W))

  override def isMaster = false
}

class SramRwIO(val dataWidth: Int, val addrWidth: Int) extends Bundle {
  val enable  = Input(Bool())
  val addr    = Input(UInt(addrWidth.W))
  val write   = Input(Bool())
  val dataIn  = Input(UInt(dataWidth.W))
  val dataOut = Output(UInt(dataWidth.W))
  val bweb    = Input(UInt(dataWidth.W))
}

class GlobalSram(val depth: Int = 2048, val dataWidth: Int = 128, val bankWidth: Int = 128) extends Module {
  require(bankWidth > 0, "GlobalSram bankWidth must be > 0")
  require(dataWidth % bankWidth == 0, s"GlobalSram dataWidth ($dataWidth) must be a multiple of bankWidth ($bankWidth)")
  val addrWidth = log2Ceil(depth)
  val io = IO(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))

  val bankNum = dataWidth / bankWidth
  val mems = Seq.fill(bankNum)(Module(new SramWrapperSp(depth = depth, dataWidth = bankWidth)))

  for ((mem, idx) <- mems.zipWithIndex) {
    mem.io.clock     := clock
    mem.io.rw.enable := io.enable
    mem.io.rw.addr   := io.addr
    mem.io.rw.write  := io.write
    mem.io.rw.dataIn := io.dataIn(bankWidth * (idx + 1) - 1, bankWidth * idx)
    mem.io.rw.bweb   := io.bweb(bankWidth * (idx + 1) - 1, bankWidth * idx)
  }

  io.dataOut := VecInit(mems.map(_.io.rw.dataOut)).asUInt
}

class LocalSram(val depth: Int = 512, val dataWidth: Int = 128, val bankWidth: Int = 128) extends Module {
  require(bankWidth > 0, "LocalSram bankWidth must be > 0")
  require(dataWidth % bankWidth == 0, s"LocalSram dataWidth ($dataWidth) must be a multiple of bankWidth ($bankWidth)")
  val addrWidth = log2Ceil(depth)
  val io = IO(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))

  val bankNum = dataWidth / bankWidth
  val mems = Seq.fill(bankNum)(Module(new SramWrapperSp(depth = depth, dataWidth = bankWidth)))

  for ((mem, idx) <- mems.zipWithIndex) {
    mem.io.clock     := clock
    mem.io.rw.enable := io.enable
    mem.io.rw.addr   := io.addr
    mem.io.rw.write  := io.write
    mem.io.rw.dataIn := io.dataIn(bankWidth * (idx + 1) - 1, bankWidth * idx)
    mem.io.rw.bweb   := io.bweb(bankWidth * (idx + 1) - 1, bankWidth * idx)
  }

  io.dataOut := VecInit(mems.map(_.io.rw.dataOut)).asUInt
}

class TempBuffer(val depth: Int = 896, val dataWidth: Int = 128, val bankDepth: Int = 224) extends Module {
  private val bankNum = 4
  require(depth == bankDepth * bankNum, "TempBuffer depth must equal bankDepth * 4")
  require(bankDepth > 0, "TempBuffer bankDepth must be > 0")

  val addrWidth = log2Ceil(depth)
  val bankAddrWidth = log2Ceil(bankDepth)
  val io = IO(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))

  when(io.enable) {
    assert(io.addr < depth.U, "TempBuffer address out of range")
  }

  val bankIdx = Wire(UInt(2.W))
  val bankAddr = Wire(UInt(bankAddrWidth.W))
  when(io.addr >= (bankDepth * 3).U) {
    bankIdx := 3.U
    bankAddr := (io.addr - (bankDepth * 3).U)(bankAddrWidth - 1, 0)
  }.elsewhen(io.addr >= (bankDepth * 2).U) {
    bankIdx := 2.U
    bankAddr := (io.addr - (bankDepth * 2).U)(bankAddrWidth - 1, 0)
  }.elsewhen(io.addr >= bankDepth.U) {
    bankIdx := 1.U
    bankAddr := (io.addr - bankDepth.U)(bankAddrWidth - 1, 0)
  }.otherwise {
    bankIdx := 0.U
    bankAddr := io.addr(bankAddrWidth - 1, 0)
  }

  val mems = Seq.fill(bankNum)(Module(new SramWrapperSp(depth = bankDepth, dataWidth = dataWidth)))
  for (m <- mems) {
    m.io.clock := clock
    m.io.rw.write := io.write
    m.io.rw.dataIn := io.dataIn
    m.io.rw.bweb := io.bweb
    m.io.rw.addr := bankAddr
  }

  mems(0).io.rw.enable := io.enable && (bankIdx === 0.U)
  mems(1).io.rw.enable := io.enable && (bankIdx === 1.U)
  mems(2).io.rw.enable := io.enable && (bankIdx === 2.U)
  mems(3).io.rw.enable := io.enable && (bankIdx === 3.U)

  val bankIdxReg = RegEnable(bankIdx, io.enable)
  io.dataOut := VecInit(mems.map(_.io.rw.dataOut))(bankIdxReg)
}

class TrigLutSram(val depth: Int = 128, val dataWidth: Int = 16) extends Module {
  require(depth > 0, "TrigLutSram depth must be > 0")
  require(dataWidth > 0, "TrigLutSram dataWidth must be > 0")
  val addrWidth = log2Ceil(depth)
  val io = IO(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))

  val mem = Module(new SramWrapperSp(depth = depth, dataWidth = dataWidth))
  mem.io.clock := clock
  mem.io.rw.enable := io.enable
  mem.io.rw.addr := io.addr
  mem.io.rw.write := io.write
  mem.io.rw.dataIn := io.dataIn
  mem.io.rw.bweb := io.bweb
  io.dataOut := mem.io.rw.dataOut
}

class SoftplusLutSram(val depth: Int = 256, val dataWidth: Int = 32) extends Module {
  require(depth > 0, "SoftplusLutSram depth must be > 0")
  require(dataWidth > 0, "SoftplusLutSram dataWidth must be > 0")
  val addrWidth = log2Ceil(depth)
  val io = IO(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))

  val mem = Module(new SramWrapperSp(depth = depth, dataWidth = dataWidth))
  mem.io.clock := clock
  mem.io.rw.enable := io.enable
  mem.io.rw.addr := io.addr
  mem.io.rw.write := io.write
  mem.io.rw.dataIn := io.dataIn
  mem.io.rw.bweb := io.bweb
  io.dataOut := mem.io.rw.dataOut
}
