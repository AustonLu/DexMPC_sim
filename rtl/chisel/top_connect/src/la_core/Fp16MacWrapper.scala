import chisel3._
import chisel3.util._
import chisel3.util.HasBlackBoxResource

class Fp16_Mac(
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends BlackBox(
  Map(
    "SIG_WIDTH" -> sigWidth,
    "EXP_WIDTH" -> expWidth,
    "IEEE_COMPLIANCE" -> ieeeCompliance,
    "EN_UBR_FLAG" -> enUbrFlag,
    "FPW" -> (1 + expWidth + sigWidth)
  )
) with HasBlackBoxResource {

  addResource("/Fp16_Mac.sv")

  val fpw: Int = 1 + expWidth + sigWidth

  val io = IO(new Bundle {
    val clk       = Input(Clock())
    val rst_n     = Input(Bool())
    val clk_en    = Input(Bool())
    val opA_in    = Input(UInt(fpw.W))
    val opB_in    = Input(UInt(fpw.W))
    val opC_in    = Input(UInt(fpw.W))
    val func_mode = Input(UInt(3.W))
    val acc_clr   = Input(Bool())
    val acc_out   = Output(UInt(fpw.W))
  })

}


//blackbox是不能generate的，必须是rawmodule，所以这里增加一层覆盖来方便generate
class Fp16_Mac_EmitTop(
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  private val fpw = 1 + expWidth + sigWidth

  val io = IO(new Bundle {
    val clk       = Input(Clock())
    val rst_n     = Input(Bool())
    val clk_en    = Input(Bool())
    val opA_in    = Input(UInt(fpw.W))
    val opB_in    = Input(UInt(fpw.W))
    val opC_in    = Input(UInt(fpw.W))
    val func_mode = Input(UInt(3.W))
    val acc_clr   = Input(Bool())
    val acc_out   = Output(UInt(fpw.W))
  })

  val dut = Module(new Fp16_Mac(sigWidth, expWidth, ieeeCompliance, enUbrFlag))
  dut.io <> io
}
