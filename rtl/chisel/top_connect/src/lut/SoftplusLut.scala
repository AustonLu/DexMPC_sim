import chisel3._
import chisel3.util._

class SoftplusIO extends Bundle {
  val in: UInt = Input(UInt(16.W))
  val start: Bool = Input(Bool())
  val out: UInt = Output(UInt(16.W))
  val busy: Bool = Output(Bool())
  val done: Bool = Output(Bool())
  val evenSram: SramRwIO = Flipped(new SramRwIO(dataWidth = 32, addrWidth = log2Ceil(256)))
  val oddSram: SramRwIO = Flipped(new SramRwIO(dataWidth = 32, addrWidth = log2Ceil(256)))
}

class SoftplusLut(val useBlackBox: Boolean = true) extends Module {
  val io: SoftplusIO = IO(new SoftplusIO)

  private val evenMem = io.evenSram
  private val oddMem = io.oddSram

  for (mem <- Seq(evenMem, oddMem)) {
    mem.enable := false.B
    mem.write := false.B
    mem.addr := 0.U
    mem.dataIn := 0.U
    mem.bweb := Fill(32, 1.U(1.W))
  }

  private val modeBypassZero = 0.U(2.W)
  private val modeBypassInput = 1.U(2.W)
  private val modeLutPos = 2.U(2.W)
  private val modeLutNeg = 3.U(2.W)

  private val sIdle :: sReadReq :: sReadResp :: Nil = Enum(3)

  private val maxLutAddr = 536.U(10.W)
  private val fp16ExpAllOnes = "b11111".U(5.W)

  private def modeNeedsLut(mode: UInt): Bool = {
    (mode === modeLutPos) || (mode === modeLutNeg)
  }

  private def shiftRightSticky(value: UInt, shift: UInt): UInt = {
    val width = value.getWidth
    val maxShift = 31
    val shifted = Wire(UInt(width.W))
    shifted := 0.U
    for (amount <- 0 to maxShift) {
      val shiftedValue =
        if (amount >= width) {
          0.U(width.W)
        } else {
          (value >> amount).asUInt
        }
      val sticky =
        if (amount == 0) {
          false.B
        } else if (amount >= width) {
          value.orR
        } else {
          value(amount - 1, 0).orR
        }
      when(shift === amount.U) {
        shifted := shiftedValue | sticky.asUInt
      }
    }
    shifted
  }

  private def fp16SubNonNeg(lhs: UInt, rhs: UInt): UInt = {
    val lhsExp = lhs(14, 10)
    val lhsFrac = lhs(9, 0)
    val rhsExp = rhs(14, 10)
    val rhsFrac = rhs(9, 0)

    val lhsIsZero = (lhsExp === 0.U) && (lhsFrac === 0.U)
    val rhsIsZero = (rhsExp === 0.U) && (rhsFrac === 0.U)
    val lhsIsSpecial = lhsExp === fp16ExpAllOnes
    val rhsIsSpecial = rhsExp === fp16ExpAllOnes
    val lhsMag = lhs(14, 0)
    val rhsMag = rhs(14, 0)

    val lhsExpEff = Mux(lhsExp === 0.U, 1.U(5.W), lhsExp)
    val rhsExpEff = Mux(rhsExp === 0.U, 1.U(5.W), rhsExp)
    val lhsSig = Mux(lhsExp === 0.U, Cat(0.U(1.W), lhsFrac), Cat(1.U(1.W), lhsFrac))
    val rhsSig = Mux(rhsExp === 0.U, Cat(0.U(1.W), rhsFrac), Cat(1.U(1.W), rhsFrac))

    val lhsExt = Cat(lhsSig, 0.U(3.W))
    val rhsExt = Cat(rhsSig, 0.U(3.W))
    val rhsAligned = shiftRightSticky(rhsExt, lhsExpEff - rhsExpEff)
    val rawDiff = (lhsExt - rhsAligned)(13, 0)

    var normExt: UInt = rawDiff
    var normExp: UInt = lhsExpEff
    for (_ <- 0 until 13) {
      val nextExt = Wire(UInt(14.W))
      val nextExp = Wire(UInt(5.W))
      val needShift = normExt.orR && (normExp > 1.U) && !normExt(13)
      nextExt := Mux(needShift, (normExt << 1)(13, 0), normExt)
      nextExp := Mux(needShift, normExp - 1.U, normExp)
      normExt = nextExt
      normExp = nextExp
    }

    val result = Wire(UInt(16.W))
    result := 0.U

    when(lhsIsSpecial && !lhsFrac.orR) {
      result := lhs
    }.elsewhen(lhsIsSpecial || rhsIsSpecial) {
      result := 0.U
    }.elsewhen(lhsIsZero || (lhsMag <= rhsMag)) {
      result := 0.U
    }.elsewhen(rhsIsZero) {
      result := lhs
    }.elsewhen(normExt(13)) {
      val mantPre = normExt(13, 3)
      val guardBit = normExt(2)
      val roundBit = normExt(1)
      val stickyBit = normExt(0)
      val inc = guardBit && (roundBit || stickyBit || mantPre(0).asBool)
      val mantRounded = mantPre + inc.asUInt

      val expRounded = Wire(UInt(6.W))
      val mantFinal = Wire(UInt(11.W))
      when(mantRounded === 2048.U) {
        expRounded := normExp + 1.U
        mantFinal := 1024.U
      }.otherwise {
        expRounded := normExp
        mantFinal := mantRounded(10, 0)
      }

      when(expRounded >= 31.U) {
        result := "h7BFF".U
      }.otherwise {
        result := Cat(0.U(1.W), expRounded(4, 0), mantFinal(9, 0))
      }
    }.otherwise {
      val fracPre = normExt(13, 3)
      val guardBit = normExt(2)
      val roundBit = normExt(1)
      val stickyBit = normExt(0)
      val inc = guardBit && (roundBit || stickyBit || fracPre(0).asBool)
      val fracRounded = fracPre + inc.asUInt

      when(fracRounded >= 1024.U) {
        result := "h0400".U
      }.otherwise {
        result := Cat(0.U(1.W), 0.U(5.W), fracRounded(9, 0))
      }
    }

    result
  }

  val stateReg = RegInit(sIdle)
  val reqModeReg = RegInit(modeBypassZero)
  val reqAbsReg = RegInit(0.U(16.W))
  val reqRowAddrReg = RegInit(0.U(log2Ceil(256).W))
  val reqBankSelReg = RegInit(false.B)
  val reqWordSelReg = RegInit(false.B)
  val resultReg = RegInit(0.U(16.W))
  val doneReg = RegInit(false.B)

  val inputBits = io.in
  val inputSign = inputBits(15)
  val absBits = inputBits & "h7FFF".U(16.W)
  val lutAddr = absBits(14, 5)
  val rowAddr = lutAddr(8, 1)
  val bankSel = lutAddr(9)
  val wordSel = lutAddr(0)
  val isFar = lutAddr > maxLutAddr

  val inputMode = Wire(UInt(2.W))
  inputMode := modeLutPos
  when(isFar && inputSign) {
    inputMode := modeBypassZero
  }.elsewhen(isFar) {
    inputMode := modeBypassInput
  }.elsewhen((absBits =/= 0.U) && inputSign) {
    inputMode := modeLutNeg
  }.otherwise {
    inputMode := modeLutPos
  }

  when(stateReg === sReadReq) {
    when(!reqBankSelReg) {
      evenMem.enable := true.B
      evenMem.addr := reqRowAddrReg
      evenMem.bweb := 0.U
    }.otherwise {
      oddMem.enable := true.B
      oddMem.addr := reqRowAddrReg
      oddMem.bweb := 0.U
    }
  }

  val lutWord = Mux(reqBankSelReg, oddMem.dataOut, evenMem.dataOut)
  val lutValue = Mux(reqWordSelReg, lutWord(31, 16), lutWord(15, 0))
  val negResult = fp16SubNonNeg(lutValue, reqAbsReg)
  val readResult = Mux(reqModeReg === modeLutNeg, negResult, lutValue)
  val bypassResult = Mux(inputMode === modeBypassInput, inputBits, 0.U(16.W))

  doneReg := false.B

  switch(stateReg) {
    is(sIdle) {
      when(io.start) {
        when(modeNeedsLut(inputMode)) {
          reqModeReg := inputMode
          reqAbsReg := absBits
          reqRowAddrReg := rowAddr
          reqBankSelReg := bankSel.asBool
          reqWordSelReg := wordSel.asBool
          stateReg := sReadReq
        }.otherwise {
          resultReg := bypassResult
          doneReg := true.B
        }
      }
    }

    is(sReadReq) {
      stateReg := sReadResp
    }

    is(sReadResp) {
      resultReg := readResult
      doneReg := true.B
      stateReg := sIdle
    }
  }

  io.out := resultReg
  io.busy := stateReg =/= sIdle
  io.done := doneReg
}
