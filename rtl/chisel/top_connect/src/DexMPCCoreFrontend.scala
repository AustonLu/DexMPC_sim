import chisel3._
import chisel3.util._
import chipmunk._
import chipmunk.amba._
import chipmunk.component.acorn._
import chipmunk.stream._

object DexMPCCoreFrontendConstants {
  val BASE_DEXMPC_ADDR = "h0000_0000".U(32.W)
  val AXI_DATA_WIDTH = 64
  val AXI_ADDR_WIDTH = 32
  val AXI_ID_WIDTH = 6

  val EXT_ADDR_ALIGN_BITS = 3
  val ACORN_S_EXT_DATA_WIDTH = AXI_DATA_WIDTH
  val ACORN_S_EXT_ADDR_WIDTH = AXI_ADDR_WIDTH
  val ACORN_S_EXT_ADDR_LS_WIDTH = 20 // use low 20 bits as external addr (2 + 15 + 3)
  val ACORN_M_CONFIG_DATA_WIDTH = AXI_DATA_WIDTH
  val ACORN_M_CONFIG_REG_ADDR_WIDTH = 6
  val ACORN_M_CONFIG_ADDR_WIDTH = ACORN_M_CONFIG_REG_ADDR_WIDTH + EXT_ADDR_ALIGN_BITS
  val ACORN_M_SRAM_DATA_WIDTH = AXI_DATA_WIDTH
  val ACORN_M_SRAM_WORD_ADDR_WIDTH = 15
  val ACORN_M_SRAM_ADDR_WIDTH = ACORN_M_SRAM_WORD_ADDR_WIDTH + EXT_ADDR_ALIGN_BITS
}

class DexMPCCoreFrontend(val numCores: Int = 4) extends Module {
  import DexMPCCoreFrontendConstants._

  val io = IO(new Bundle {
    val sAxi = Slave(new Axi4IO(dataWidth = AXI_DATA_WIDTH, addrWidth = AXI_ADDR_WIDTH, idWidth = AXI_ID_WIDTH))

    val config = Flipped(new DexMPCCoreConfigIO(numCores = numCores))
    val allDoneReg = Input(UInt(32.W))

    val sramAccess = Master(new BufferAccessIO(dataWidth = 128, addrWidth = ACORN_M_SRAM_WORD_ADDR_WIDTH))
  })

  val uAxiToAcornDp = Module(
    new Axi4ToAcornDpBridge(dataWidth = io.sAxi.dataWidth, addrWidth = io.sAxi.addrWidth, idWidth = io.sAxi.idWidth)
  )
  uAxiToAcornDp.io.sAxi4 <> io.sAxi

  val uAcornDemux = Module(new DexMPCCoreAcornDemux)
  uAcornDemux.io.sExt <> uAxiToAcornDp.io.mAcornW

  val uConfigRegBank = Module(new DexMPCCoreConfigRegBank(coreNum = numCores))
  uConfigRegBank.io.access <> uAcornDemux.io.mConfig
  io.config.in := uConfigRegBank.io.configIn
  uConfigRegBank.io.configOut := io.config.out
  uConfigRegBank.io.allDoneReg := io.allDoneReg

  val uSramAccess = Module(
    new DexMPCBufferGate(
      bufAddrWidth = ACORN_M_SRAM_WORD_ADDR_WIDTH,
      extAddrWidth = ACORN_M_SRAM_ADDR_WIDTH,
      bufDataWidth = 128,
      extDataWidth = ACORN_M_SRAM_DATA_WIDTH
    )
  )
  uSramAccess.io.sAcornDp <> uAcornDemux.io.mSram
  io.sramAccess <> uSramAccess.io.mBufAccess
}

class DexMPCCoreAcornDemux extends Module {
  import DexMPCCoreFrontendConstants._

  val io = IO(new Bundle {
    val sExt = Slave(new AcornDpIO(dataWidth = ACORN_S_EXT_DATA_WIDTH, addrWidth = ACORN_S_EXT_ADDR_WIDTH))
    val mConfig = Master(new AcornDpIO(dataWidth = ACORN_M_CONFIG_DATA_WIDTH, addrWidth = ACORN_M_CONFIG_ADDR_WIDTH))
    val mSram = Master(new AcornDpIO(dataWidth = ACORN_M_SRAM_DATA_WIDTH, addrWidth = ACORN_M_SRAM_ADDR_WIDTH))
  })

  private def extAddrOffset(addr: UInt): UInt =
    (addr - BASE_DEXMPC_ADDR)(ACORN_S_EXT_ADDR_LS_WIDTH - 1, 0)

  val wrAddrLow = extAddrOffset(io.sExt.wr.cmd.bits.addr)
  val wrSel = wrAddrLow(ACORN_S_EXT_ADDR_LS_WIDTH - 1, ACORN_M_SRAM_ADDR_WIDTH)
  val wrSel01 = Mux(wrSel === 1.U, 1.U, 0.U)
  val wrSelQueue = Module(new Queue(UInt(1.W), entries = 256, pipe = true, flow = true))
  wrSelQueue.io.enq.valid := io.sExt.wr.cmd.fire
  wrSelQueue.io.enq.bits := wrSel01

  val extWrCmdDemux = StreamDemux(in = io.sExt.wr.cmd, select = wrSel01, num = 2)

  io.mConfig.wr.cmd handshakeFrom extWrCmdDemux(0)
  io.mConfig.wr.cmd.bits.addr := extAddrOffset(extWrCmdDemux(0).bits.addr)(ACORN_M_CONFIG_ADDR_WIDTH - 1, 0)
  io.mConfig.wr.cmd.bits.wmask := extWrCmdDemux(0).bits.wmask
  io.mConfig.wr.cmd.bits.wdata := extWrCmdDemux(0).bits.wdata

  io.mSram.wr.cmd handshakeFrom extWrCmdDemux(1)
  io.mSram.wr.cmd.bits.addr := extAddrOffset(extWrCmdDemux(1).bits.addr)(ACORN_M_SRAM_ADDR_WIDTH - 1, 0)
  io.mSram.wr.cmd.bits.wmask := extWrCmdDemux(1).bits.wmask
  io.mSram.wr.cmd.bits.wdata := extWrCmdDemux(1).bits.wdata

  val wrRespRaw = StreamMux(
    select = wrSelQueue.io.deq.bits,
    ins = VecInit(io.mConfig.wr.resp, io.mSram.wr.resp)
  )
  io.sExt.wr.resp.valid := wrRespRaw.valid && wrSelQueue.io.deq.valid
  io.sExt.wr.resp.bits := wrRespRaw.bits
  wrRespRaw.ready := io.sExt.wr.resp.ready && wrSelQueue.io.deq.valid
  wrSelQueue.io.deq.ready := io.sExt.wr.resp.fire

  val rdAddrLow = extAddrOffset(io.sExt.rd.cmd.bits.addr)
  val rdSel = rdAddrLow(ACORN_S_EXT_ADDR_LS_WIDTH - 1, ACORN_M_SRAM_ADDR_WIDTH)
  val rdSel01 = Mux(rdSel === 1.U, 1.U, 0.U)
  val rdSelQueue = Module(new Queue(UInt(1.W), entries = 256, pipe = true, flow = true))
  rdSelQueue.io.enq.valid := io.sExt.rd.cmd.fire
  rdSelQueue.io.enq.bits := rdSel01

  val extRdCmdDemux = StreamDemux(in = io.sExt.rd.cmd, select = rdSel01, num = 2)

  io.mConfig.rd.cmd handshakeFrom extRdCmdDemux(0)
  io.mConfig.rd.cmd.bits.addr := extAddrOffset(extRdCmdDemux(0).bits.addr)(ACORN_M_CONFIG_ADDR_WIDTH - 1, 0)

  io.mSram.rd.cmd handshakeFrom extRdCmdDemux(1)
  io.mSram.rd.cmd.bits.addr := extAddrOffset(extRdCmdDemux(1).bits.addr)(ACORN_M_SRAM_ADDR_WIDTH - 1, 0)

  val rdRespRaw = StreamMux(
    select = rdSelQueue.io.deq.bits,
    ins = VecInit(io.mConfig.rd.resp, io.mSram.rd.resp)
  )
  io.sExt.rd.resp.valid := rdRespRaw.valid && rdSelQueue.io.deq.valid
  io.sExt.rd.resp.bits := rdRespRaw.bits
  rdRespRaw.ready := io.sExt.rd.resp.ready && rdSelQueue.io.deq.valid
  rdSelQueue.io.deq.ready := io.sExt.rd.resp.fire
}

class DexMPCBufferGate(
  val bufAddrWidth: Int,
  val extAddrWidth: Int,
  val bufDataWidth: Int = 128,
  val extDataWidth: Int = 64
) extends Module {
  import DexMPCCoreFrontendConstants._

  require(
    bufDataWidth == extDataWidth * 2,
    s"DexMPCBufferGate expects bufDataWidth == 2 * extDataWidth, got bufDataWidth=$bufDataWidth extDataWidth=$extDataWidth"
  )
  require(
    extDataWidth == 64,
    s"DexMPCBufferGate expects 64-bit external write data, got extDataWidth=$extDataWidth"
  )
  require(
    extAddrWidth == bufAddrWidth + EXT_ADDR_ALIGN_BITS,
    s"DexMPCBufferGate expects extAddrWidth == bufAddrWidth + $EXT_ADDR_ALIGN_BITS, got extAddrWidth=$extAddrWidth bufAddrWidth=$bufAddrWidth"
  )
  val io = IO(new Bundle {
    val sAcornDp = Slave(new AcornDpIO(dataWidth = extDataWidth, addrWidth = extAddrWidth))
    val mBufAccess = Master(new BufferAccessIO(dataWidth = bufDataWidth, addrWidth = bufAddrWidth))
  })

  val uDp2Sp = Module(new AcornDpToSpBridge(io.sAcornDp.dataWidth, io.sAcornDp.addrWidth))
  uDp2Sp.io.sAcornD <> io.sAcornDp
  val sAcornSp = uDp2Sp.io.mAcornS

  private def extToBufAddr(addr: UInt): UInt = addr(extAddrWidth - 1, EXT_ADDR_ALIGN_BITS)

  private val extMaskWidth = extDataWidth / 8
  private val maskFull64 = ((BigInt(1) << extMaskWidth) - 1).U(extMaskWidth.W)
  private val maskLow32 = ((BigInt(1) << 4) - 1).U(extMaskWidth.W)
  private val maskHigh32 = (((BigInt(1) << 4) - 1) << 4).U(extMaskWidth.W)

  private val wrStateIdle :: wrStateFullSecond :: wrStateSplitHigh0 :: wrStateSplitLow1 :: wrStateSplitHigh1 :: Nil = Enum(5)
  val wrStateReg = RegInit(wrStateIdle)

  val fullFirstAddrReg = RegInit(0.U(extAddrWidth.W))
  val fullFirstDataReg = RegInit(0.U(extDataWidth.W))
  val fullFirstMaskReg = RegInit(0.U(extDataWidth.W))

  val splitBufAddrReg = RegInit(0.U(bufAddrWidth.W))
  val split0fAddrReg = RegInit(0.U(extAddrWidth.W))
  val splitF0AddrReg = RegInit(0.U(extAddrWidth.W))
  val splitLo0Reg = RegInit(0.U(32.W))
  val splitHi0Reg = RegInit(0.U(32.W))
  val splitLo1Reg = RegInit(0.U(32.W))

  val cmdWrData = WireDefault(0.U(bufDataWidth.W))
  val cmdAddrNext = WireDefault(0.U(bufAddrWidth.W))
  val cmdAddrReg = RegInit(0.U(bufAddrWidth.W))
  val cmdAddrUpdate = WireDefault(false.B)
  val cmdEnable = WireDefault(false.B)
  val cmdIsWrite = WireDefault(false.B)
  val cmdBweb = WireDefault(0.U(bufDataWidth.W))

  val wmaskBits = FillInterleaved(8, sAcornSp.cmd.bits.wmask).asUInt

  sAcornSp.cmd.ready := true.B
  val cmdFire = sAcornSp.cmd.fire
  val isRead = sAcornSp.cmd.bits.read
  val isWrite = !isRead
  val doRead = cmdFire && isRead

  val doWriteCommit = WireDefault(false.B)
  val writeCommitAddr = WireDefault(0.U(bufAddrWidth.W))
  val writeCommitData = WireDefault(0.U(bufDataWidth.W))
  val writeCommitBweb = WireDefault(0.U(bufDataWidth.W))

  when(doRead) {
    wrStateReg := wrStateIdle
  }.elsewhen(cmdFire && isWrite) {
    switch(wrStateReg) {
      is(wrStateIdle) {
        when(sAcornSp.cmd.bits.wmask === maskFull64) {
          wrStateReg := wrStateFullSecond
          fullFirstAddrReg := sAcornSp.cmd.bits.addr
          fullFirstDataReg := sAcornSp.cmd.bits.wdata
          fullFirstMaskReg := wmaskBits
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskLow32) {
          wrStateReg := wrStateSplitHigh0
          splitBufAddrReg := extToBufAddr(sAcornSp.cmd.bits.addr)
          split0fAddrReg := sAcornSp.cmd.bits.addr
          splitLo0Reg := sAcornSp.cmd.bits.wdata(31, 0)
        }.otherwise {
          wrStateReg := wrStateIdle
        }
      }

      is(wrStateFullSecond) {
        when((sAcornSp.cmd.bits.wmask === maskFull64) && (sAcornSp.cmd.bits.addr === fullFirstAddrReg)) {
          wrStateReg := wrStateIdle
          doWriteCommit := true.B
          writeCommitAddr := extToBufAddr(fullFirstAddrReg)
          writeCommitData := Cat(sAcornSp.cmd.bits.wdata, fullFirstDataReg)
          writeCommitBweb := ~(Cat(wmaskBits, fullFirstMaskReg))
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskFull64) {
          wrStateReg := wrStateFullSecond
          fullFirstAddrReg := sAcornSp.cmd.bits.addr
          fullFirstDataReg := sAcornSp.cmd.bits.wdata
          fullFirstMaskReg := wmaskBits
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskLow32) {
          wrStateReg := wrStateSplitHigh0
          splitBufAddrReg := extToBufAddr(sAcornSp.cmd.bits.addr)
          split0fAddrReg := sAcornSp.cmd.bits.addr
          splitLo0Reg := sAcornSp.cmd.bits.wdata(31, 0)
        }.otherwise {
          wrStateReg := wrStateIdle
        }
      }

      is(wrStateSplitHigh0) {
        when(
          (sAcornSp.cmd.bits.wmask === maskHigh32) &&
          (extToBufAddr(sAcornSp.cmd.bits.addr) === splitBufAddrReg)
        ) {
          wrStateReg := wrStateSplitLow1
          splitF0AddrReg := sAcornSp.cmd.bits.addr
          splitHi0Reg := sAcornSp.cmd.bits.wdata(63, 32)
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskLow32) {
          wrStateReg := wrStateSplitHigh0
          splitBufAddrReg := extToBufAddr(sAcornSp.cmd.bits.addr)
          split0fAddrReg := sAcornSp.cmd.bits.addr
          splitLo0Reg := sAcornSp.cmd.bits.wdata(31, 0)
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskFull64) {
          wrStateReg := wrStateFullSecond
          fullFirstAddrReg := sAcornSp.cmd.bits.addr
          fullFirstDataReg := sAcornSp.cmd.bits.wdata
          fullFirstMaskReg := wmaskBits
        }.otherwise {
          wrStateReg := wrStateIdle
        }
      }

      is(wrStateSplitLow1) {
        when(
          (sAcornSp.cmd.bits.wmask === maskLow32) &&
          (sAcornSp.cmd.bits.addr === split0fAddrReg) &&
          (extToBufAddr(sAcornSp.cmd.bits.addr) === splitBufAddrReg)
        ) {
          wrStateReg := wrStateSplitHigh1
          splitLo1Reg := sAcornSp.cmd.bits.wdata(31, 0)
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskLow32) {
          wrStateReg := wrStateSplitHigh0
          splitBufAddrReg := extToBufAddr(sAcornSp.cmd.bits.addr)
          split0fAddrReg := sAcornSp.cmd.bits.addr
          splitLo0Reg := sAcornSp.cmd.bits.wdata(31, 0)
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskFull64) {
          wrStateReg := wrStateFullSecond
          fullFirstAddrReg := sAcornSp.cmd.bits.addr
          fullFirstDataReg := sAcornSp.cmd.bits.wdata
          fullFirstMaskReg := wmaskBits
        }.otherwise {
          wrStateReg := wrStateIdle
        }
      }

      is(wrStateSplitHigh1) {
        when(
          (sAcornSp.cmd.bits.wmask === maskHigh32) &&
          (sAcornSp.cmd.bits.addr === splitF0AddrReg) &&
          (extToBufAddr(sAcornSp.cmd.bits.addr) === splitBufAddrReg)
        ) {
          wrStateReg := wrStateIdle
          doWriteCommit := true.B
          writeCommitAddr := splitBufAddrReg
          writeCommitData := Cat(
            sAcornSp.cmd.bits.wdata(63, 32),
            splitLo1Reg,
            splitHi0Reg,
            splitLo0Reg
          )
          writeCommitBweb := 0.U
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskLow32) {
          wrStateReg := wrStateSplitHigh0
          splitBufAddrReg := extToBufAddr(sAcornSp.cmd.bits.addr)
          split0fAddrReg := sAcornSp.cmd.bits.addr
          splitLo0Reg := sAcornSp.cmd.bits.wdata(31, 0)
        }.elsewhen(sAcornSp.cmd.bits.wmask === maskFull64) {
          wrStateReg := wrStateFullSecond
          fullFirstAddrReg := sAcornSp.cmd.bits.addr
          fullFirstDataReg := sAcornSp.cmd.bits.wdata
          fullFirstMaskReg := wmaskBits
        }.otherwise {
          wrStateReg := wrStateIdle
        }
      }
    }
  }

  when(doRead) {
    cmdAddrNext := extToBufAddr(sAcornSp.cmd.bits.addr)
    cmdAddrUpdate := true.B
  }.elsewhen(doWriteCommit) {
    cmdAddrNext := writeCommitAddr
    cmdAddrUpdate := true.B
  }

  when(cmdAddrUpdate) {
    cmdAddrReg := cmdAddrNext
  }

  when(doWriteCommit) {
    cmdWrData := writeCommitData
    cmdBweb := writeCommitBweb
  }

  cmdEnable := doRead || doWriteCommit
  cmdIsWrite := doWriteCommit

  io.mBufAccess.enable := cmdEnable
  io.mBufAccess.address := Mux(cmdAddrUpdate, cmdAddrNext, cmdAddrReg)
  io.mBufAccess.isWrite := cmdIsWrite
  io.mBufAccess.writeData := cmdWrData
  io.mBufAccess.bweb := cmdBweb

  val rdStateIdle :: rdStateExpectSecond :: rdStateExpectHighFirst :: rdStateExpectHighSecond :: Nil = Enum(4)
  val rdStateReg = RegInit(rdStateIdle)
  val rdBaseAddrReg = RegInit(0.U(extAddrWidth.W))
  val readSelNext = WireDefault(false.B)

  private def isAligned8(addr: UInt): Bool = addr(EXT_ADDR_ALIGN_BITS - 1, 0) === 0.U
  private def plus4(addr: UInt): UInt = (addr + 4.U)(extAddrWidth - 1, 0)

  when(cmdFire && isWrite) {
    rdStateReg := rdStateIdle
  }.elsewhen(doRead) {
    switch(rdStateReg) {
      is(rdStateIdle) {
        readSelNext := false.B
        when(isAligned8(sAcornSp.cmd.bits.addr)) {
          rdStateReg := rdStateExpectSecond
          rdBaseAddrReg := sAcornSp.cmd.bits.addr
        }.otherwise {
          rdStateReg := rdStateIdle
        }
      }

      is(rdStateExpectSecond) {
        when(sAcornSp.cmd.bits.addr === rdBaseAddrReg) {
          readSelNext := true.B
          rdStateReg := rdStateIdle
        }.elsewhen(sAcornSp.cmd.bits.addr === plus4(rdBaseAddrReg)) {
          readSelNext := false.B
          rdStateReg := rdStateExpectHighFirst
        }.elsewhen(isAligned8(sAcornSp.cmd.bits.addr)) {
          readSelNext := false.B
          rdStateReg := rdStateExpectSecond
          rdBaseAddrReg := sAcornSp.cmd.bits.addr
        }.otherwise {
          readSelNext := false.B
          rdStateReg := rdStateIdle
        }
      }

      is(rdStateExpectHighFirst) {
        when(sAcornSp.cmd.bits.addr === rdBaseAddrReg) {
          readSelNext := true.B
          rdStateReg := rdStateExpectHighSecond
        }.elsewhen(isAligned8(sAcornSp.cmd.bits.addr)) {
          readSelNext := false.B
          rdStateReg := rdStateExpectSecond
          rdBaseAddrReg := sAcornSp.cmd.bits.addr
        }.otherwise {
          readSelNext := false.B
          rdStateReg := rdStateIdle
        }
      }

      is(rdStateExpectHighSecond) {
        when(sAcornSp.cmd.bits.addr === plus4(rdBaseAddrReg)) {
          readSelNext := true.B
          rdStateReg := rdStateIdle
        }.elsewhen(isAligned8(sAcornSp.cmd.bits.addr)) {
          readSelNext := false.B
          rdStateReg := rdStateExpectSecond
          rdBaseAddrReg := sAcornSp.cmd.bits.addr
        }.otherwise {
          readSelNext := false.B
          rdStateReg := rdStateIdle
        }
      }
    }
  }

  val respValidReg = RegNext(cmdFire, false.B)
  val respSelReg = RegNext(readSelNext, init = false.B)
  val respDataReg = Mux(
    respSelReg,
    io.mBufAccess.readData(bufDataWidth - 1, extDataWidth),
    io.mBufAccess.readData(extDataWidth - 1, 0)
  )
  sAcornSp.resp.valid := respValidReg
  sAcornSp.resp.bits.rdata := respDataReg
  sAcornSp.resp.bits.error := false.B
}

class DexMPCCoreConfigRegBank(val coreNum: Int = 4) extends Module {
  import DexMPCCoreFrontendConstants._

  private val regCount = 64
  private val inCount = 22
  private val isLoopRegIdx = 63

  val io = IO(new Bundle {
    val access = Slave(new AcornDpIO(dataWidth = ACORN_M_CONFIG_DATA_WIDTH, addrWidth = ACORN_M_CONFIG_ADDR_WIDTH))
    val configIn = Flipped(new DexMPCCoreConfigIO(numCores = coreNum).in.cloneType)
    val configOut = Flipped(new DexMPCCoreConfigIO(numCores = coreNum).out.cloneType)
    val allDoneReg = Input(UInt(32.W))
  })

  val regs = RegInit(VecInit(Seq.fill(regCount)(0.U(32.W))))
  val isLoopReg = regs(isLoopRegIdx)
  val cmdCtrlRaw = Wire(Vec(coreNum, UInt(32.W)))
  val cmdCtrlPrev = RegInit(VecInit(Seq.fill(coreNum)(0.U(32.W))))

  // Output regs are backdoor-updated each cycle
  def outBase(idx: Int) = inCount + idx
  for (c <- 0 until coreNum) {
    regs(outBase(0) + c) := io.configOut.cmdStatus(c)
    regs(outBase(4) + c) := io.configOut.doneCount(c)
    regs(outBase(8) + c) := io.configOut.lastDone(c)
    regs(outBase(12) + c) := io.configOut.lastDoneCycle(c)
    regs(outBase(16) + c) := io.configOut.cycleRdData(c)
    regs(outBase(20) + c) := io.configOut.addReduceReg(c)
    regs(outBase(24) + c) := io.configOut.cmpReduceReg0(c)
    regs(outBase(28) + c) := io.configOut.cmpReduceReg1(c)
  }
  regs(outBase(32)) := io.configOut.engineStatus
  regs(outBase(33)) := io.allDoneReg
  regs(outBase(34)) := io.configOut.done_signal
  regs(outBase(35)) := io.configOut.spareOut1

  val uDp2Sp = Module(new AcornDpToSpBridge(io.access.dataWidth, io.access.addrWidth))
  uDp2Sp.io.sAcornD <> io.access
  val sAcornSp = uDp2Sp.io.mAcornS

  val addrIdx = sAcornSp.cmd.bits.addr(ACORN_M_CONFIG_ADDR_WIDTH - 1, EXT_ADDR_ALIGN_BITS)
  val addrReg = RegEnable(addrIdx, 0.U(ACORN_M_CONFIG_REG_ADDR_WIDTH.W), sAcornSp.cmd.fire)

  val wmask32 = FillInterleaved(8, sAcornSp.cmd.bits.wmask(3, 0)).asUInt
  val wdata32 = sAcornSp.cmd.bits.wdata(31, 0)

  sAcornSp.cmd.ready := true.B
  when(sAcornSp.cmd.fire && !sAcornSp.cmd.bits.read) {
    when(addrIdx < regCount.U) {
      regs(addrIdx) := (wdata32 & wmask32) | (regs(addrIdx) & ~wmask32)
    }
  }

  val respValidReg = RegNext(sAcornSp.cmd.fire, false.B)
  sAcornSp.resp.valid := respValidReg
  sAcornSp.resp.bits.rdata := Cat(0.U((ACORN_M_CONFIG_DATA_WIDTH - 32).W), regs(addrReg))
  sAcornSp.resp.bits.error := false.B

  // Drive config inputs from regs
  for (c <- 0 until coreNum) {
    for (w <- 0 until 3) {
      io.configIn.cmdWord(c)(w) := regs(c * 3 + w)
    }
    cmdCtrlRaw(c) := regs(12 + c)
    io.configIn.cmdCtrl(c) := Mux(
      isLoopReg(0),
      cmdCtrlRaw(c),
      Mux((cmdCtrlRaw(c) === 1.U) && (cmdCtrlPrev(c) === 0.U), 1.U(32.W), 0.U(32.W))
    )
    io.configIn.cycleRdAddr(c) := regs(16 + c)
    cmdCtrlPrev(c) := cmdCtrlRaw(c)
  }
  io.configIn.spareIn0 := regs(20)
  io.configIn.spareIn1 := regs(21)
}
