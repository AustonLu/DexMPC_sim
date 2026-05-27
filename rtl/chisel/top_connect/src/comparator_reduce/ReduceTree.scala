import chisel3._
import chisel3.util._
import chisel3.util.HasBlackBoxResource

class Fp16_Add(
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0
) extends BlackBox(
  Map(
    "SIG_WIDTH" -> sigWidth,
    "EXP_WIDTH" -> expWidth,
    "IEEE_COMPLIANCE" -> ieeeCompliance,
    "FPW" -> (1 + expWidth + sigWidth)
  )
) with HasBlackBoxResource {

  addResource("/Fp16_Add.sv")

  val fpw: Int = 1 + expWidth + sigWidth

  val io = IO(new Bundle {
    val a = Input(UInt(fpw.W))
    val b = Input(UInt(fpw.W))
    val rnd = Input(UInt(3.W))
    val z = Output(UInt(fpw.W))
    val status = Output(UInt(8.W))
  })
}

class Fp16AddWrapper(
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0
) extends Module {
  private val fpw = 1 + expWidth + sigWidth

  val io = IO(new Bundle {
    val a = Input(UInt(fpw.W))
    val b = Input(UInt(fpw.W))
    val z = Output(UInt(fpw.W))
  })

  val adder = Module(new Fp16_Add(sigWidth, expWidth, ieeeCompliance))
  adder.io.a := io.a
  adder.io.b := io.b
  adder.io.rnd := 0.U
  io.z := adder.io.z
}

class AdderComparatorReduceNode(
  val fpw: Int = 16,
  val idxWidth: Int = 4,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0
) extends Module {
  val io = IO(new Bundle {
    val mode = Input(UInt(1.W)) // 0: adder, 1: comparator
    val leftValue = Input(UInt(fpw.W))
    val rightValue = Input(UInt(fpw.W))
    val leftIndex = Input(UInt(idxWidth.W))
    val rightIndex = Input(UInt(idxWidth.W))
    val outValue = Output(UInt(fpw.W))
    val outIndex = Output(UInt(idxWidth.W))
  })

  def orderKey(x: UInt): UInt = {
    val signMask = (BigInt(1) << (fpw - 1)).U(fpw.W)
    Mux(x(fpw - 1).asBool, ~x, x ^ signMask)
  }

  val leftIsLower = orderKey(io.leftValue) < orderKey(io.rightValue)
  val cmpValue = Mux(leftIsLower, io.leftValue, io.rightValue)
  val cmpIndex = Mux(leftIsLower, io.leftIndex, io.rightIndex)

  val isAdderMode = io.mode === 0.U
  val adder = Module(new Fp16AddWrapper(sigWidth, expWidth, ieeeCompliance))
  adder.io.a := Mux(isAdderMode, io.leftValue, 0.U)
  adder.io.b := Mux(isAdderMode, io.rightValue, 0.U)

  io.outValue := Mux(isAdderMode, adder.io.z, cmpValue)
  io.outIndex := Mux(isAdderMode, 0.U(idxWidth.W), cmpIndex)
}

class ReduceTree(
  val numInputs: Int = 16,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0
) extends Module {
  require(numInputs > 1, "numInputs must be greater than 1")
  require((numInputs & (numInputs - 1)) == 0, "numInputs must be power of 2")

  private val fpw = 1 + expWidth + sigWidth
  private val idxWidth = log2Ceil(numInputs)
  private val levels = log2Ceil(numInputs)

  val io = IO(new Bundle {
    val mode = Input(UInt(1.W)) // 0: adder tree, 1: comparator tree
    val in = Input(Vec(numInputs, UInt(fpw.W)))
    val idx = Output(UInt(idxWidth.W))
    val value = Output(UInt(fpw.W))
  })

  val stageValues = Seq.tabulate(levels + 1) { level =>
    Wire(Vec(numInputs >> level, UInt(fpw.W)))
  }
  val stageIndices = Seq.tabulate(levels + 1) { level =>
    Wire(Vec(numInputs >> level, UInt(idxWidth.W)))
  }

  stageValues(0) := io.in
  for (i <- 0 until numInputs) {
    stageIndices(0)(i) := i.U(idxWidth.W)
  }

  for (level <- 0 until levels) {
    val nodesInLevel = numInputs >> (level + 1)
    for (node <- 0 until nodesInLevel) {
      val reduceNode = Module(
        new AdderComparatorReduceNode(fpw, idxWidth, sigWidth, expWidth, ieeeCompliance)
      )
      reduceNode.io.mode := io.mode
      reduceNode.io.leftValue := stageValues(level)(2 * node)
      reduceNode.io.rightValue := stageValues(level)(2 * node + 1)
      reduceNode.io.leftIndex := stageIndices(level)(2 * node)
      reduceNode.io.rightIndex := stageIndices(level)(2 * node + 1)

      stageValues(level + 1)(node) := reduceNode.io.outValue
      stageIndices(level + 1)(node) := reduceNode.io.outIndex
    }
  }

  io.value := stageValues(levels)(0)
  io.idx := Mux(io.mode === 1.U, stageIndices(levels)(0), 0.U(idxWidth.W))
}
