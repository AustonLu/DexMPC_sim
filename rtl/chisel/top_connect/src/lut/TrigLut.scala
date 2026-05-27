import chisel3._
import chisel3.util._

class TrigLutIO extends Bundle {
  val in: UInt = Input(UInt(16.W))
  val start: Bool = Input(Bool())
  val sin: UInt = Output(UInt(16.W))
  val cos: UInt = Output(UInt(16.W))
  val busy: Bool = Output(Bool())
  val done: Bool = Output(Bool())
  val sinEvenSram: SramRwIO = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
  val sinOddSram: SramRwIO = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
  val cosEvenSram: SramRwIO = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
  val cosOddSram: SramRwIO = Flipped(new SramRwIO(dataWidth = 16, addrWidth = log2Ceil(128)))
}

class TrigLut(val useBlackBox: Boolean = true) extends Module {
  require(useBlackBox, "TrigLut expects external SRAM-backed LUTs")

  val io: TrigLutIO = IO(new TrigLutIO)

  private val sinEvenMem = io.sinEvenSram
  private val sinOddMem = io.sinOddSram
  private val cosEvenMem = io.cosEvenSram
  private val cosOddMem = io.cosOddSram

  for (mem <- Seq(sinEvenMem, sinOddMem, cosEvenMem, cosOddMem)) {
    mem.enable := false.B
    mem.write := false.B
    mem.addr := 0.U
    mem.dataIn := 0.U
    mem.bweb := Fill(16, 1.U(1.W))
  }

  private val sIdle :: sReduce :: sReadReq :: sReadResp :: Nil = Enum(4)

  private val q1 = 0.U(2.W)
  private val q2 = 1.U(2.W)
  private val q3 = 2.U(2.W)
  private val q4 = 3.U(2.W)

  private val piHalfFp16 = "h3E48".U(16.W)
  private val piFp16 = "h4248".U(16.W)
  private val piThreeHalfFp16 = "h44B6".U(16.W)
  private val twoPiFp16 = "h4648".U(16.W)

  private val piHalfBits = piHalfFp16(14, 0)
  private val piBits = piFp16(14, 0)
  private val piThreeHalfBits = piThreeHalfFp16(14, 0)
  private val twoPiBits = twoPiFp16(14, 0)

  private val fp16ExpAllOnes = "b11111".U(5.W)

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

  private def applyNegate(bits: UInt, negate: Bool): UInt = {
    Mux(negate, bits ^ "h8000".U(16.W), bits)
  }

  val stateReg = RegInit(sIdle)
  val inputNegativeReg = RegInit(false.B)
  val reducedAbsFp16Reg = RegInit(0.U(16.W))
  val reqSinNegateReg = RegInit(false.B)
  val reqCosNegateReg = RegInit(false.B)
  val reqSinBankSelReg = RegInit(false.B)
  val reqCosBankSelReg = RegInit(false.B)
  val reqSinRowAddrReg = RegInit(0.U(log2Ceil(128).W))
  val reqCosRowAddrReg = RegInit(0.U(log2Ceil(128).W))
  val sinReg = RegInit(0.U(16.W))
  val cosReg = RegInit(0.U(16.W))
  val doneReg = RegInit(false.B)

  val inputBits = io.in
  val inputNegative = inputBits(15) && inputBits(14, 0).orR
  val absFp16 = inputBits & "h7FFF".U(16.W)
  val reducedAbsBits = reducedAbsFp16Reg(14, 0)
  val reducedIsSpecial = reducedAbsFp16Reg(14, 10) === fp16ExpAllOnes

  val quadrant = Wire(UInt(2.W))
  quadrant := q4
  when(reducedAbsBits <= piHalfBits) {
    quadrant := q1
  }.elsewhen(reducedAbsBits <= piBits) {
    quadrant := q2
  }.elsewhen(reducedAbsBits <= piThreeHalfBits) {
    quadrant := q3
  }.otherwise {
    quadrant := q4
  }

  val thetaSinBits = Wire(UInt(16.W))
  val thetaCosBits = Wire(UInt(16.W))
  thetaSinBits := fp16SubNonNeg(twoPiFp16, reducedAbsFp16Reg)
  thetaCosBits := fp16SubNonNeg(reducedAbsFp16Reg, piThreeHalfFp16)

  switch(quadrant) {
    is(q1) {
      thetaSinBits := reducedAbsFp16Reg
      thetaCosBits := fp16SubNonNeg(piHalfFp16, reducedAbsFp16Reg)
    }
    is(q2) {
      thetaSinBits := fp16SubNonNeg(piFp16, reducedAbsFp16Reg)
      thetaCosBits := fp16SubNonNeg(reducedAbsFp16Reg, piHalfFp16)
    }
    is(q3) {
      thetaSinBits := fp16SubNonNeg(reducedAbsFp16Reg, piFp16)
      thetaCosBits := fp16SubNonNeg(piThreeHalfFp16, reducedAbsFp16Reg)
    }
    is(q4) {
      thetaSinBits := fp16SubNonNeg(twoPiFp16, reducedAbsFp16Reg)
      thetaCosBits := fp16SubNonNeg(reducedAbsFp16Reg, piThreeHalfFp16)
    }
  }

  val sinCopyAddr = thetaSinBits(13, 6)
  val cosCopyAddr = thetaCosBits(13, 6)
  val sinBankSel = sinCopyAddr(7)
  val cosBankSel = cosCopyAddr(7)
  val sinRowAddr = sinCopyAddr(6, 0)
  val cosRowAddr = cosCopyAddr(6, 0)

  val sinNegate = ((quadrant === q3) || (quadrant === q4)) ^ inputNegativeReg
  val cosNegate = (quadrant === q2) || (quadrant === q3)

  when(stateReg === sReadReq) {
    when(!reqSinBankSelReg) {
      sinEvenMem.enable := true.B
      sinEvenMem.addr := reqSinRowAddrReg
      sinEvenMem.bweb := 0.U
    }.otherwise {
      sinOddMem.enable := true.B
      sinOddMem.addr := reqSinRowAddrReg
      sinOddMem.bweb := 0.U
    }

    when(!reqCosBankSelReg) {
      cosEvenMem.enable := true.B
      cosEvenMem.addr := reqCosRowAddrReg
      cosEvenMem.bweb := 0.U
    }.otherwise {
      cosOddMem.enable := true.B
      cosOddMem.addr := reqCosRowAddrReg
      cosOddMem.bweb := 0.U
    }
  }

  val lutSinCopyValue = Mux(reqSinBankSelReg, sinOddMem.dataOut, sinEvenMem.dataOut)
  val lutCosCopyValue = Mux(reqCosBankSelReg, cosOddMem.dataOut, cosEvenMem.dataOut)

  doneReg := false.B

  switch(stateReg) {
    is(sIdle) {
      when(io.start) {
        inputNegativeReg := inputNegative
        reducedAbsFp16Reg := absFp16
        stateReg := sReduce
      }
    }

    is(sReduce) {
      when(!reducedIsSpecial && (reducedAbsBits > twoPiBits)) {
        reducedAbsFp16Reg := fp16SubNonNeg(reducedAbsFp16Reg, twoPiFp16)
      }.otherwise {
        reqSinNegateReg := sinNegate
        reqCosNegateReg := cosNegate
        reqSinBankSelReg := sinBankSel
        reqCosBankSelReg := cosBankSel
        reqSinRowAddrReg := sinRowAddr
        reqCosRowAddrReg := cosRowAddr
        stateReg := sReadReq
      }
    }

    is(sReadReq) {
      stateReg := sReadResp
    }

    is(sReadResp) {
      sinReg := applyNegate(lutSinCopyValue, reqSinNegateReg)
      cosReg := applyNegate(lutCosCopyValue, reqCosNegateReg)
      doneReg := true.B
      stateReg := sIdle
    }
  }

  io.sin := sinReg
  io.cos := cosReg
  io.busy := stateReg =/= sIdle
  io.done := doneReg
}
