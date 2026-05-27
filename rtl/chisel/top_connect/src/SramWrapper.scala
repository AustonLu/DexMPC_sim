import chisel3._
import chisel3.util._

class SramWrapperSp(val depth: Int = 64, val dataWidth: Int = 64) 
  extends BlackBox(Map(
      "DEPTH" -> depth, 
      "ADDR_WIDTH" -> log2Ceil(depth),
      "DATA_WIDTH" -> dataWidth)) with HasBlackBoxResource {

  val addrWidth: Int = log2Ceil(depth)
  val io = IO(new Bundle {
    val clock = Input(Clock())

    val rw = new Bundle {
      val enable  = Input(Bool())
      val addr    = Input(UInt(addrWidth.W))
      val write   = Input(Bool())
      val dataIn  = Input(UInt(dataWidth.W))
      val dataOut = Output(UInt(dataWidth.W))
      val bweb    = Input(UInt(dataWidth.W))
    }

    // val config = Slave(new BufferSramConfigIO())
  })
  addResource("/SramWrapperSP.sv")
}
