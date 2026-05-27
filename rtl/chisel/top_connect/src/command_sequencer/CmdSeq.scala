import chisel3._
import chisel3.util._

object CmdSeqOpcode {
  val OP_ABS: UInt = "b001".U(3.W)
  val OP_REDUCE: UInt = "b010".U(3.W)
  val OP_LA: UInt = "b011".U(3.W)
  val OP_LUT: UInt = "b100".U(3.W)
  val OP_DATALAYOUT: UInt = "b101".U(3.W)
}

object CmdSeqSubop {
  val SUB_ABS: UInt = 0.U(4.W)

  val SUB_CMP_REDUCE: UInt = 0.U(4.W)
  val SUB_ADD_TREE: UInt = 1.U(4.W)

  val SUB_GEMM: UInt = 0.U(4.W)
  val SUB_MUL: UInt = 1.U(4.W)
  val SUB_ADD: UInt = 2.U(4.W)

  val SUB_SIN: UInt = 0.U(4.W)
  val SUB_COS: UInt = 1.U(4.W)
  val SUB_SOFTPLUS: UInt = 2.U(4.W)

  val SUB_ASSEMBLE: UInt = 0.U(4.W)
  val SUB_TRANSPOSE: UInt = 1.U(4.W)
}

class CmdSeqAbsCmd(val addrWidth: Int, val dimWidth: Int, val reqIdWidth: Int) extends Bundle {
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val dstBase = UInt(addrWidth.W)
  val rows = UInt(dimWidth.W)
  val cols = UInt(dimWidth.W)
  val reqId = UInt(reqIdWidth.W)
}

class CmdSeqAbsRsp(val addrWidth: Int, val dimWidth: Int, val reqIdWidth: Int) extends Bundle {
  val reqId = UInt(reqIdWidth.W)
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val dstBase = UInt(addrWidth.W)
  val rows = UInt(dimWidth.W)
  val cols = UInt(dimWidth.W)
  val done = Bool()
}

class CmdSeqReduceCmd(val addrWidth: Int, val elemCountWidth: Int, val reqIdWidth: Int) extends Bundle {
  val mode = UInt(1.W)
  val srcSramId = UInt(2.W)
  val baseAddr = UInt(addrWidth.W)
  val elemCount = UInt(elemCountWidth.W)
  val reqId = UInt(reqIdWidth.W)
}

class CmdSeqReduceRsp(val fpw: Int, val addrWidth: Int, val elemCountWidth: Int, val reqIdWidth: Int) extends Bundle {
  val reqId = UInt(reqIdWidth.W)
  val mode = UInt(1.W)
  val srcSramId = UInt(2.W)
  val baseAddr = UInt(addrWidth.W)
  val elemCount = UInt(elemCountWidth.W)
  val resultValue = UInt(fpw.W)
  val resultIndex = UInt(elemCountWidth.W)
}

class CmdSeqLutCmd(val addrWidth: Int, val dimWidth: Int) extends Bundle {
  val funcSel = UInt(2.W)
  val trigSel = UInt(2.W)
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val dstBase = UInt(addrWidth.W)
  val rows = UInt(dimWidth.W)
  val cols = UInt(dimWidth.W)
}

class CmdSeqLutRsp extends Bundle {
  val done = Bool()
}

class CmdSeqDataLayoutCmd(val addrWidth: Int, val dimWidth: Int, val reqIdWidth: Int) extends Bundle {
  val mode = Bool()
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val srcRows = UInt(dimWidth.W)
  val srcCols = UInt(dimWidth.W)
  val dstBase = UInt(addrWidth.W)
  val dstRows = UInt(dimWidth.W)
  val dstCols = UInt(dimWidth.W)
  val offsetRow = UInt(dimWidth.W)
  val offsetCol = UInt(dimWidth.W)
  val reqId = UInt(reqIdWidth.W)
}

class CmdSeqDataLayoutRsp(val addrWidth: Int, val dimWidth: Int, val reqIdWidth: Int) extends Bundle {
  val mode = Bool()
  val srcSramId = UInt(2.W)
  val dstSramId = UInt(2.W)
  val srcBase = UInt(addrWidth.W)
  val srcRows = UInt(dimWidth.W)
  val srcCols = UInt(dimWidth.W)
  val dstBase = UInt(addrWidth.W)
  val dstRows = UInt(dimWidth.W)
  val dstCols = UInt(dimWidth.W)
  val offsetRow = UInt(dimWidth.W)
  val offsetCol = UInt(dimWidth.W)
  val reqId = UInt(reqIdWidth.W)
  val done = Bool()
}

class CmdSeqMacIf(val addrWidth: Int, val dimWidth: Int, val fpw: Int) extends Bundle {
  val opSel = Output(UInt(2.W))
  val start = Output(Bool())
  val nRows = Output(UInt(dimWidth.W))
  val mCols = Output(UInt(dimWidth.W))
  val kDim = Output(UInt(dimWidth.W))
  val alpha = Output(UInt(fpw.W))
  val baseA = Output(UInt(addrWidth.W))
  val baseB = Output(UInt(addrWidth.W))
  val baseC = Output(UInt(addrWidth.W))
  val baseASramId = Output(UInt(2.W))
  val baseBSramId = Output(UInt(2.W))
  val baseCSramId = Output(UInt(2.W))
  val busy = Input(Bool())
  val done = Input(Bool())
}

class CmdSeq(
  val fifoDepth: Int = 32,
  val addrWidth: Int = 11,
  val dimWidth: Int = 12,
  val reqIdWidth: Int = 12,
  val fpw: Int = 16,
  val elemCountWidth: Int = 12
) extends Module {
  require(fifoDepth > 0, "CmdSeq fifoDepth must be > 0")

  private val cmdWidth = 96
  private val ptrWidth = math.max(1, log2Ceil(fifoDepth))
  private val countWidth = math.max(1, log2Ceil(fifoDepth + 1))

  val io = IO(new Bundle {
    val cmdIn = Flipped(Decoupled(UInt(cmdWidth.W)))

    val fifoFull = Output(Bool())
    val fifoEmpty = Output(Bool())
    val fifoCount = Output(UInt(countWidth.W))

    val busy = Output(Bool())
    val idle = Output(Bool())

    val activeValid = Output(Bool())
    val activeCmdId = Output(UInt(reqIdWidth.W))
    val activeOpcode = Output(UInt(3.W))
    val activeSubop = Output(UInt(4.W))
    val activeGroupEnd = Output(Bool())
    val activeAddr0SramId = Output(UInt(2.W))
    val activeAddr1SramId = Output(UInt(2.W))
    val activeAddr2SramId = Output(UInt(2.W))
    val activeAddr0Word = Output(UInt(addrWidth.W))
    val activeAddr1Word = Output(UInt(addrWidth.W))
    val activeAddr2Word = Output(UInt(addrWidth.W))

    val doneValid = Output(Bool())
    val doneCmdId = Output(UInt(reqIdWidth.W))
    val doneOpcode = Output(UInt(3.W))
    val doneSubop = Output(UInt(4.W))
    val doneGroupEnd = Output(Bool())

    val illegalCmd = Output(Bool())
    val illegalCmdId = Output(UInt(reqIdWidth.W))

    val addReduceValue = Output(UInt(fpw.W))
    val addReduceCmdId = Output(UInt(reqIdWidth.W))
    val addReduceValid = Output(Bool())

    val cmpReduceValue = Output(UInt(fpw.W))
    val cmpReduceIndex = Output(UInt(elemCountWidth.W))
    val cmpReduceCmdId = Output(UInt(reqIdWidth.W))
    val cmpReduceValid = Output(Bool())

    val absCmdReq = Decoupled(new CmdSeqAbsCmd(addrWidth, dimWidth, reqIdWidth))
    val absCmdRsp = Flipped(Decoupled(new CmdSeqAbsRsp(addrWidth, dimWidth, reqIdWidth)))

    val reduceCmdReq = Decoupled(new CmdSeqReduceCmd(addrWidth, elemCountWidth, reqIdWidth))
    val reduceCmdRsp = Flipped(Decoupled(new CmdSeqReduceRsp(fpw, addrWidth, elemCountWidth, reqIdWidth)))

    val lutCmdReq = Decoupled(new CmdSeqLutCmd(addrWidth, dimWidth))
    val lutCmdRsp = Flipped(Decoupled(new CmdSeqLutRsp))

    val dataLayoutCmdReq = Decoupled(new CmdSeqDataLayoutCmd(addrWidth, dimWidth, reqIdWidth))
    val dataLayoutCmdRsp = Flipped(Decoupled(new CmdSeqDataLayoutRsp(addrWidth, dimWidth, reqIdWidth)))

    val mac = new CmdSeqMacIf(addrWidth, dimWidth, fpw)
  })

  private def cmdId(cmd: UInt): UInt = cmd(95, 84)
  private def opcode(cmd: UInt): UInt = cmd(83, 81)
  private def subop(cmd: UInt): UInt = cmd(80, 77)
  private def groupEnd(cmd: UInt): Bool = cmd(76)
  private def addr0(cmd: UInt): UInt = cmd(74, 62)
  private def addr1(cmd: UInt): UInt = cmd(61, 49)
  private def addr2(cmd: UInt): UInt = cmd(48, 36)
  private def dim0(cmd: UInt): UInt = cmd(35, 24)
  private def dim1(cmd: UInt): UInt = cmd(23, 12)
  private def dim2(cmd: UInt): UInt = cmd(11, 0)

  val fifo = Reg(Vec(fifoDepth, UInt(cmdWidth.W)))
  val head = RegInit(0.U(ptrWidth.W))
  val tail = RegInit(0.U(ptrWidth.W))
  val count = RegInit(0.U(countWidth.W))

  val fifoFull = count === fifoDepth.U
  val fifoEmpty = count === 0.U

  io.cmdIn.ready := !fifoFull

  val doPush = io.cmdIn.valid && io.cmdIn.ready
  val doPop = WireDefault(false.B)

  when(doPush) {
    fifo(tail) := io.cmdIn.bits
    tail := Mux(tail === (fifoDepth - 1).U, 0.U, tail + 1.U)
  }

  when(doPop) {
    head := Mux(head === (fifoDepth - 1).U, 0.U, head + 1.U)
  }

  val popCmd = fifo(head)

  val nextCount = count + doPush.asUInt - doPop.asUInt
  count := nextCount

  val activeCmdReg = RegInit(0.U(cmdWidth.W))
  val activeValidReg = RegInit(false.B)

  val donePulseReg = RegInit(false.B)
  val doneCmdIdReg = RegInit(0.U(reqIdWidth.W))
  val doneOpcodeReg = RegInit(0.U(3.W))
  val doneSubopReg = RegInit(0.U(4.W))
  val doneGroupEndReg = RegInit(false.B)

  val illegalPulseReg = RegInit(false.B)
  val illegalCmdIdReg = RegInit(0.U(reqIdWidth.W))

  val addReduceValueReg = RegInit(0.U(fpw.W))
  val addReduceCmdIdReg = RegInit(0.U(reqIdWidth.W))
  val addReduceValidReg = RegInit(false.B)

  val cmpReduceValueReg = RegInit(0.U(fpw.W))
  val cmpReduceIndexReg = RegInit(0.U(elemCountWidth.W))
  val cmpReduceCmdIdReg = RegInit(0.U(reqIdWidth.W))
  val cmpReduceValidReg = RegInit(false.B)

  val mulAlphaReg = RegInit(0.U(fpw.W))

  val sIdle :: sDispatch :: sWaitDone :: Nil = Enum(3)
  val state = RegInit(sIdle)

  val activeOpcode = opcode(activeCmdReg)
  val activeSubop = subop(activeCmdReg)
  val activeCmdId = cmdId(activeCmdReg)
  val activeGroupEnd = groupEnd(activeCmdReg)

  val addr0Field = addr0(activeCmdReg)
  val addr1Field = addr1(activeCmdReg)
  val addr2Field = addr2(activeCmdReg)

  val addr0SramId = addr0Field(12, 11)
  val addr1SramId = addr1Field(12, 11)
  val addr2SramId = addr2Field(12, 11)

  val addr0Word = addr0Field(10, 0)
  val addr1Word = addr1Field(10, 0)
  val addr2Word = addr2Field(10, 0)

  val dim0Field = dim0(activeCmdReg)
  val dim1Field = dim1(activeCmdReg)
  val dim2Field = dim2(activeCmdReg)

  val isAbs = activeOpcode === CmdSeqOpcode.OP_ABS
  val isReduce = activeOpcode === CmdSeqOpcode.OP_REDUCE
  val isLa = activeOpcode === CmdSeqOpcode.OP_LA
  val isLut = activeOpcode === CmdSeqOpcode.OP_LUT
  val isDataLayout = activeOpcode === CmdSeqOpcode.OP_DATALAYOUT

  val isMul = isLa && (activeSubop === CmdSeqSubop.SUB_MUL)

  val illegalOpcode = !(isAbs || isReduce || isLa || isLut || isDataLayout)
  val illegalSubop = MuxLookup(activeOpcode, true.B)(Seq(
    CmdSeqOpcode.OP_ABS -> (activeSubop =/= CmdSeqSubop.SUB_ABS),
    CmdSeqOpcode.OP_REDUCE -> (activeSubop =/= CmdSeqSubop.SUB_CMP_REDUCE && activeSubop =/= CmdSeqSubop.SUB_ADD_TREE),
    CmdSeqOpcode.OP_LA -> (activeSubop =/= CmdSeqSubop.SUB_GEMM && activeSubop =/= CmdSeqSubop.SUB_MUL && activeSubop =/= CmdSeqSubop.SUB_ADD),
    CmdSeqOpcode.OP_LUT -> (activeSubop =/= CmdSeqSubop.SUB_SIN && activeSubop =/= CmdSeqSubop.SUB_COS && activeSubop =/= CmdSeqSubop.SUB_SOFTPLUS),
    CmdSeqOpcode.OP_DATALAYOUT -> (activeSubop =/= CmdSeqSubop.SUB_ASSEMBLE && activeSubop =/= CmdSeqSubop.SUB_TRANSPOSE)
  ))
  val illegalCmd = activeValidReg && (illegalOpcode || illegalSubop)

  io.absCmdReq.valid := false.B
  io.absCmdReq.bits := 0.U.asTypeOf(io.absCmdReq.bits)
  io.absCmdRsp.ready := false.B

  io.reduceCmdReq.valid := false.B
  io.reduceCmdReq.bits := 0.U.asTypeOf(io.reduceCmdReq.bits)
  io.reduceCmdRsp.ready := false.B

  io.lutCmdReq.valid := false.B
  io.lutCmdReq.bits := 0.U.asTypeOf(io.lutCmdReq.bits)
  io.lutCmdRsp.ready := false.B

  io.dataLayoutCmdReq.valid := false.B
  io.dataLayoutCmdReq.bits := 0.U.asTypeOf(io.dataLayoutCmdReq.bits)
  io.dataLayoutCmdRsp.ready := false.B

  io.mac.opSel := 0.U
  io.mac.start := false.B
  io.mac.nRows := 0.U
  io.mac.mCols := 0.U
  io.mac.kDim := 0.U
  io.mac.alpha := mulAlphaReg
  io.mac.baseA := 0.U
  io.mac.baseB := 0.U
  io.mac.baseC := 0.U
  io.mac.baseASramId := 0.U
  io.mac.baseBSramId := 0.U
  io.mac.baseCSramId := 0.U

  val absFire = io.absCmdReq.fire
  val reduceFire = io.reduceCmdReq.fire
  val lutFire = io.lutCmdReq.fire
  val dataLayoutFire = io.dataLayoutCmdReq.fire
  val macLaunch = io.mac.start

  val absDone = io.absCmdRsp.fire
  val reduceDone = io.reduceCmdRsp.fire
  val lutDone = io.lutCmdRsp.fire
  val dataLayoutDone = io.dataLayoutCmdRsp.fire
  val macDone = io.mac.done

  val dispatching = state === sDispatch
  val dispatchOk = dispatching && !illegalCmd
  val waiting = state === sWaitDone

  when(dispatchOk && isAbs) {
    io.absCmdReq.valid := true.B
    io.absCmdReq.bits.srcSramId := addr0SramId
    io.absCmdReq.bits.dstSramId := addr1SramId
    io.absCmdReq.bits.srcBase := addr0Word
    io.absCmdReq.bits.dstBase := addr1Word
    io.absCmdReq.bits.rows := dim0Field
    io.absCmdReq.bits.cols := dim1Field
    io.absCmdReq.bits.reqId := activeCmdId
  }

  when(dispatchOk && isReduce) {
    io.reduceCmdReq.valid := true.B
    io.reduceCmdReq.bits.srcSramId := addr0SramId
    io.reduceCmdReq.bits.baseAddr := addr0Word
    io.reduceCmdReq.bits.elemCount := dim0Field(elemCountWidth - 1, 0)
    io.reduceCmdReq.bits.reqId := activeCmdId
    io.reduceCmdReq.bits.mode := Mux(activeSubop === CmdSeqSubop.SUB_CMP_REDUCE, 1.U, 0.U)
  }

  when(dispatchOk && isLut) {
    io.lutCmdReq.valid := true.B
    io.lutCmdReq.bits.srcSramId := addr0SramId
    io.lutCmdReq.bits.dstSramId := addr1SramId
    io.lutCmdReq.bits.srcBase := addr0Word
    io.lutCmdReq.bits.dstBase := addr1Word
    io.lutCmdReq.bits.rows := dim0Field
    io.lutCmdReq.bits.cols := dim1Field
    io.lutCmdReq.bits.funcSel := Mux(activeSubop === CmdSeqSubop.SUB_SOFTPLUS, 1.U, 0.U)
    io.lutCmdReq.bits.trigSel := Mux(activeSubop === CmdSeqSubop.SUB_COS, 1.U, 0.U)
  }

  when(dispatchOk && isDataLayout) {
    val offCol = addr2Word.pad(dimWidth)
    val isAssemble = activeSubop === CmdSeqSubop.SUB_ASSEMBLE
    val dstRows = Mux(isAssemble, dim0Field +& dim2Field, dim1Field)
    val dstCols = Mux(isAssemble, dim1Field +& offCol, dim0Field)

    io.dataLayoutCmdReq.valid := true.B
    io.dataLayoutCmdReq.bits.mode := isAssemble
    io.dataLayoutCmdReq.bits.srcSramId := addr0SramId
    io.dataLayoutCmdReq.bits.dstSramId := addr1SramId
    io.dataLayoutCmdReq.bits.srcBase := addr0Word
    io.dataLayoutCmdReq.bits.srcRows := dim0Field
    io.dataLayoutCmdReq.bits.srcCols := dim1Field
    io.dataLayoutCmdReq.bits.dstBase := addr1Word
    io.dataLayoutCmdReq.bits.dstRows := dstRows(dimWidth - 1, 0)
    io.dataLayoutCmdReq.bits.dstCols := dstCols(dimWidth - 1, 0)
    io.dataLayoutCmdReq.bits.offsetRow := dim2Field
    io.dataLayoutCmdReq.bits.offsetCol := offCol
    io.dataLayoutCmdReq.bits.reqId := activeCmdId
  }

  when(dispatchOk && isLa) {
    val isGemm = activeSubop === CmdSeqSubop.SUB_GEMM
    val isMulSub = activeSubop === CmdSeqSubop.SUB_MUL
    val isAdd = activeSubop === CmdSeqSubop.SUB_ADD

    io.mac.opSel := Mux(isGemm, 0.U, Mux(isMulSub, 1.U, 2.U))
    io.mac.nRows := Mux(isGemm, dim1Field, dim0Field)
    io.mac.mCols := Mux(isGemm, dim0Field, dim1Field)
    io.mac.kDim := Mux(isGemm, dim2Field, 0.U)
    io.mac.baseA := addr0Word
    io.mac.baseB := Mux(isGemm || isAdd, addr1Word, 0.U)
    io.mac.baseC := Mux(isGemm || isAdd, addr2Word, addr1Word)
    io.mac.alpha := mulAlphaReg
    io.mac.baseASramId := addr0SramId
    io.mac.baseBSramId := Mux(isGemm || isAdd, addr1SramId, 0.U)
    io.mac.baseCSramId := Mux(isGemm || isAdd, addr2SramId, addr1SramId)

    io.mac.start := !io.mac.busy
  }

  when(waiting && isAbs) {
    io.absCmdRsp.ready := true.B
  }

  when(waiting && isReduce) {
    io.reduceCmdRsp.ready := true.B
  }

  when(waiting && isLut) {
    io.lutCmdRsp.ready := true.B
  }

  when(waiting && isDataLayout) {
    io.dataLayoutCmdRsp.ready := true.B
  }

  val doneThisCycle = WireDefault(false.B)
  val illegalThisCycle = WireDefault(false.B)

  donePulseReg := doneThisCycle
  illegalPulseReg := illegalThisCycle

  switch(state) {
    is(sIdle) {
      when(!fifoEmpty) {
        doPop := true.B
        activeCmdReg := popCmd
        activeValidReg := true.B
        val popIsMul = (opcode(popCmd) === CmdSeqOpcode.OP_LA) && (subop(popCmd) === CmdSeqSubop.SUB_MUL)
        val popMulAlpha = Cat(dim2(popCmd)(2, 0), addr2(popCmd))
        mulAlphaReg := Mux(popIsMul, popMulAlpha, 0.U)
        state := sDispatch
      }
    }

    is(sDispatch) {
      when(illegalCmd) {
        doneThisCycle := true.B
        doneCmdIdReg := activeCmdId
        doneOpcodeReg := activeOpcode
        doneSubopReg := activeSubop
        doneGroupEndReg := activeGroupEnd
        illegalThisCycle := true.B
        illegalCmdIdReg := activeCmdId
        activeValidReg := false.B
        state := sIdle
      }.elsewhen(isAbs && absFire) {
        state := sWaitDone
      }.elsewhen(isReduce && reduceFire) {
        state := sWaitDone
      }.elsewhen(isLut && lutFire) {
        state := sWaitDone
      }.elsewhen(isDataLayout && dataLayoutFire) {
        state := sWaitDone
      }.elsewhen(isLa && macLaunch) {
        state := sWaitDone
      }
    }

    is(sWaitDone) {
      when(isAbs && absDone) {
        doneThisCycle := true.B
      }.elsewhen(isReduce && reduceDone) {
        doneThisCycle := true.B
        when(io.reduceCmdRsp.bits.mode === 0.U) {
          addReduceValueReg := io.reduceCmdRsp.bits.resultValue
          addReduceCmdIdReg := io.reduceCmdRsp.bits.reqId
          addReduceValidReg := true.B
        }.otherwise {
          cmpReduceValueReg := io.reduceCmdRsp.bits.resultValue
          cmpReduceIndexReg := io.reduceCmdRsp.bits.resultIndex
          cmpReduceCmdIdReg := io.reduceCmdRsp.bits.reqId
          cmpReduceValidReg := true.B
        }
      }.elsewhen(isLut && lutDone) {
        doneThisCycle := true.B
      }.elsewhen(isDataLayout && dataLayoutDone) {
        doneThisCycle := true.B
      }.elsewhen(isLa && macDone) {
        doneThisCycle := true.B
      }

      when(doneThisCycle) {
        doneCmdIdReg := activeCmdId
        doneOpcodeReg := activeOpcode
        doneSubopReg := activeSubop
        doneGroupEndReg := activeGroupEnd
        activeValidReg := false.B
        state := sIdle
      }
    }
  }

  io.fifoFull := fifoFull
  io.fifoEmpty := fifoEmpty
  io.fifoCount := count

  io.busy := (state =/= sIdle) || activeValidReg
  io.idle := !io.busy

  io.activeValid := activeValidReg
  io.activeCmdId := activeCmdId
  io.activeOpcode := activeOpcode
  io.activeSubop := activeSubop
  io.activeGroupEnd := activeGroupEnd
  io.activeAddr0SramId := addr0SramId
  io.activeAddr1SramId := addr1SramId
  io.activeAddr2SramId := addr2SramId
  io.activeAddr0Word := addr0Word
  io.activeAddr1Word := addr1Word
  io.activeAddr2Word := addr2Word

  io.doneValid := donePulseReg
  io.doneCmdId := doneCmdIdReg
  io.doneOpcode := doneOpcodeReg
  io.doneSubop := doneSubopReg
  io.doneGroupEnd := doneGroupEndReg

  io.illegalCmd := illegalPulseReg
  io.illegalCmdId := illegalCmdIdReg

  io.addReduceValue := addReduceValueReg
  io.addReduceCmdId := addReduceCmdIdReg
  io.addReduceValid := addReduceValidReg

  io.cmpReduceValue := cmpReduceValueReg
  io.cmpReduceIndex := cmpReduceIndexReg
  io.cmpReduceCmdId := cmpReduceCmdIdReg
  io.cmpReduceValid := cmpReduceValidReg
}
