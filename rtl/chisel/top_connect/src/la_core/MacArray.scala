import chisel3._
import chisel3.util._

object MacArrayFuncMode {
  val MAC: UInt       = 0.U(3.W)
  val MUL_ADD_C: UInt = 1.U(3.W)
  val MUL: UInt       = 2.U(3.W)
  val ADD: UInt       = 3.U(3.W)
  val ACC: UInt       = 4.U(3.W)
  val IDLE: UInt      = 5.U(3.W)
}

class MacArray(
  val n: Int = 16,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  require(n > 0, "MacArray n must be > 0")

  private val fpw = 1 + expWidth + sigWidth
  private val tileSizeWidth = log2Ceil(n + 1)
  private val readSelWidth = math.max(1, log2Ceil(n))

  val io = IO(new Bundle {
    val aVecIn = Input(Vec(n, UInt(fpw.W)))
    val bVecIn = Input(Vec(n, UInt(fpw.W)))

    val funcMode = Input(UInt(3.W))
    val computeEn = Input(Bool())
    val accClearPulse = Input(Bool())

    val tileRows = Input(UInt(tileSizeWidth.W))
    val tileCols = Input(UInt(tileSizeWidth.W))

    val readEn = Input(Bool())
    val readByCol = Input(Bool())
    val readSel = Input(UInt(readSelWidth.W))

    val readPackOut = Output(UInt((n * fpw).W))
    val readPackValid = Output(Bool())
  })

  private val zeroData = 0.U(fpw.W)
  private val rstN = !reset.asBool

  val peAcc = Wire(Vec(n, Vec(n, UInt(fpw.W))))

  for (i <- 0 until n) {
    val rowActive = i.U(tileSizeWidth.W) < io.tileRows
    for (j <- 0 until n) {
      val pe = Module(new Fp16_Mac(sigWidth, expWidth, ieeeCompliance, enUbrFlag))
      val colActive = j.U(tileSizeWidth.W) < io.tileCols
      val peActive = rowActive && colActive
      val runThisCycle = peActive && io.computeEn
      val clkEn = peActive && (io.computeEn || io.accClearPulse)

      pe.io.clk := clock
      pe.io.rst_n := rstN
      pe.io.clk_en := clkEn
      pe.io.opA_in := Mux(runThisCycle, io.aVecIn(i), zeroData)
      pe.io.opB_in := Mux(runThisCycle, io.bVecIn(j), zeroData)
      pe.io.opC_in := Mux(runThisCycle, io.aVecIn(i), zeroData)
      pe.io.func_mode := Mux(runThisCycle, io.funcMode, MacArrayFuncMode.IDLE)
      pe.io.acc_clr := io.accClearPulse

      peAcc(i)(j) := pe.io.acc_out
    }
  }

  private val readSelClamped = Mux(io.readSel >= n.U, (n - 1).U, io.readSel)
  private val selectedAccRow = peAcc(readSelClamped)
  private val selectedAccCol = VecInit((0 until n).map(i => peAcc(i)(readSelClamped)))
  private val selectedPack = Mux(io.readByCol, selectedAccCol.asUInt, selectedAccRow.asUInt)

  io.readPackOut := Mux(io.readEn, selectedPack, 0.U)
  io.readPackValid := io.readEn
}
