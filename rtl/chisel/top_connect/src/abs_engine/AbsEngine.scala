import chisel3._
import chisel3.util._

class AbsCore(
  val depth: Int = 2048,
  val wordWidth: Int = 256,
  val dimWidth: Int = 16
) extends Module {
  require(wordWidth > 0, "AbsCore wordWidth must be > 0")
  require(wordWidth % 16 == 0, s"AbsCore wordWidth ($wordWidth) must be a multiple of FP16 width (16)")

  private val fp16Width = 16
  private val fp16PerWord = wordWidth / fp16Width
  private val elemCountWidth = dimWidth * 2 + 1

  val addrWidth = log2Ceil(depth)
  val io = IO(new Bundle {
    val start = Input(Bool())
    val srcBase = Input(UInt(addrWidth.W))
    val dstBase = Input(UInt(addrWidth.W))
    val rows = Input(UInt(dimWidth.W))
    val cols = Input(UInt(dimWidth.W))

    val busy = Output(Bool())
    val done = Output(Bool())

    val sram = Flipped(new SramRwIO(dataWidth = wordWidth, addrWidth = addrWidth))
  })

  val sIdle :: sReadReq :: sReadResp :: sWriteReq :: sWriteResp :: Nil = Enum(5)
  val state = RegInit(sIdle)

  val srcAddrReg = RegInit(0.U(addrWidth.W))
  val dstAddrReg = RegInit(0.U(addrWidth.W))
  val remainingElemsReg = RegInit(0.U(elemCountWidth.W))
  val doneReg = RegInit(false.B)

  val fp16PerWordU = fp16PerWord.U(elemCountWidth.W)
  val validElemsThisWord = Mux(
    remainingElemsReg > fp16PerWordU,
    fp16PerWordU,
    remainingElemsReg
  )

  val signClearBweb = VecInit((0 until fp16PerWord).map { idx =>
    Mux(idx.U(elemCountWidth.W) < validElemsThisWord, 0.U(fp16Width.W), Fill(fp16Width, 1.U(1.W)))
  }).asUInt

  val signClearMask = VecInit(Seq.fill(fp16PerWord)("h7FFF".U(fp16Width.W))).asUInt
  val inWordReg = RegInit(0.U(wordWidth.W))
  val outWordReg = RegInit(0.U(wordWidth.W))

  io.sram.enable := false.B
  io.sram.addr := srcAddrReg
  io.sram.write := false.B
  io.sram.dataIn := outWordReg
  io.sram.bweb := signClearBweb

  io.busy := state =/= sIdle
  io.done := doneReg

  doneReg := false.B

  switch(state) {
    is(sIdle) {
      when(io.start) {
        val totalElems = io.rows * io.cols
        srcAddrReg := io.srcBase
        dstAddrReg := io.dstBase
        remainingElemsReg := totalElems
        when(totalElems === 0.U) {
          doneReg := true.B
        }.otherwise {
          state := sReadReq
        }
      }
    }

    is(sReadReq) {
      io.sram.enable := true.B
      io.sram.addr := srcAddrReg
      io.sram.write := false.B
      io.sram.dataIn := 0.U(wordWidth.W)
      io.sram.bweb := Fill(wordWidth, 1.U(1.W))

      state := sReadResp
    }

    is(sReadResp) {
      inWordReg := io.sram.dataOut
      outWordReg := io.sram.dataOut & signClearMask
      state := sWriteReq
    }

    is(sWriteReq) {
      io.sram.enable := true.B
      io.sram.addr := dstAddrReg
      io.sram.write := true.B
      io.sram.dataIn := outWordReg
      io.sram.bweb := signClearBweb

      state := sWriteResp
    }

    is(sWriteResp) {
      val nextRemaining = remainingElemsReg - validElemsThisWord
      remainingElemsReg := nextRemaining
      srcAddrReg := srcAddrReg + 1.U
      dstAddrReg := dstAddrReg + 1.U

      when(nextRemaining === 0.U) {
        state := sIdle
        doneReg := true.B
      }.otherwise {
        state := sReadReq
      }
    }
  }
}
