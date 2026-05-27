import chisel3._
import chisel3.util._
import chipmunk._

class DexMPCCoreTop(
  val numCores: Int = 4,
  val fifoDepth: Int = 32,
  val globalDepth: Int = 2048,
  val localDepth: Int = 512,
  val tempDepth: Int = 896,
  val sramDataWidth: Int = 128,
  val dimWidth: Int = 12,
  val reqIdWidth: Int = 12,
  val elemCountWidth: Int = 12,
  val sigWidth: Int = 10,
  val expWidth: Int = 5,
  val ieeeCompliance: Int = 0,
  val enUbrFlag: Int = 0
) extends Module {
  private val fpw = 1 + expWidth + sigWidth
  private val addrWidth = log2Ceil(globalDepth)
  private val localAddrWidth = log2Ceil(localDepth)
  private val tempAddrWidth = log2Ceil(tempDepth)

  private val sharedCoreIdx = 0

  val io = IO(new Bundle {
    // Config regs (inputs)
    val cmdWord = Input(Vec(numCores, Vec(3, UInt(32.W)))) // [0]=word0, [1]=word1, [2]=word2
    val cmdCtrl = Input(Vec(numCores, UInt(32.W)))         // bit0: cmd_push
    val cycleRdAddr = Input(Vec(numCores, UInt(32.W)))     // low reqIdWidth bits used
    val spareIn0 = Input(UInt(32.W))
    val spareIn1 = Input(UInt(32.W))

    // Status regs (outputs)
    val cmdStatus = Output(Vec(numCores, UInt(32.W)))
    val doneCount = Output(Vec(numCores, UInt(32.W)))
    val lastDone = Output(Vec(numCores, UInt(32.W)))
    val lastDoneCycle = Output(Vec(numCores, UInt(32.W)))
    val cycleRdData = Output(Vec(numCores, UInt(32.W)))
    val addReduceReg = Output(Vec(numCores, UInt(32.W)))
    val cmpReduceReg0 = Output(Vec(numCores, UInt(32.W)))
    val cmpReduceReg1 = Output(Vec(numCores, UInt(32.W)))
    val engineStatus = Output(UInt(32.W))
    val allDoneReg = Output(UInt(32.W))
    val done_signal = Output(UInt(32.W))
    val spareOut1 = Output(UInt(32.W))

    val Buffer_exts = Slave(new BufferAccessIO(dataWidth = 128, addrWidth = 4 + 11))
  })

  private def connectSramArb(mem: SramRwIO, clients: Seq[SramRwIO], name: String): Unit = {
    require(clients.nonEmpty, s"$name arb needs at least one client")
    val reqs = VecInit(clients.map(_.enable))
    val anyReq = reqs.asUInt.orR
    val grantOH = PriorityEncoderOH(reqs.asUInt)
    val grantVec = grantOH.asBools.take(clients.length)

    mem.enable := anyReq
    mem.write := Mux1H(grantVec, clients.map(_.write))
    mem.addr := Mux1H(grantVec, clients.map(_.addr))
    mem.dataIn := Mux1H(grantVec, clients.map(_.dataIn))
    mem.bweb := Mux1H(grantVec, clients.map(_.bweb))

    clients.foreach(_.dataOut := mem.dataOut)

    when(PopCount(reqs) > 1.U) {
      assert(false.B, s"$name SRAM contention")
    }
  }

  private def reduceSramToClient(port: ReduceTreeCoreCtrlSramIO, dataWidth: Int, addrWidth: Int): SramRwIO = {
    val wire = Wire(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))
    wire.enable := port.enable
    wire.addr := port.addr
    wire.write := port.write
    wire.dataIn := port.dataIn
    wire.bweb := port.bweb
    port.dataOut := wire.dataOut
    wire
  }


  private val extAddrWidth = 11
  private val extSelWidth = 4
  private val extSel = io.Buffer_exts.address(extAddrWidth + extSelWidth - 1, extAddrWidth)
  private val extAddr = io.Buffer_exts.address(extAddrWidth - 1, 0)

  private def makeExtPort(sel: Int, dataWidth: Int, addrWidth: Int): SramRwIO = {
    val port = Wire(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))
    val hit = io.Buffer_exts.enable && (extSel === sel.U)
    port.enable := hit
    port.write := hit && io.Buffer_exts.isWrite
    port.addr := extAddr(addrWidth - 1, 0)
    port.dataIn := io.Buffer_exts.writeData(dataWidth - 1, 0)
    port.bweb := io.Buffer_exts.bweb(dataWidth - 1, 0)
    port
  }

  private val idGlobal = 0x0
  private val idLocal0 = 0x1
  private val idLocal1 = 0x2
  private val idLocal2 = 0x3
  private val idLocal3 = 0x4
  private val idTemp0 = 0x5
  private val idTemp1 = 0x6
  private val idTemp2 = 0x7
  private val idTemp3 = 0x8
  private val idTrigSinEven = 0x9
  private val idTrigSinOdd = 0xA
  private val idTrigCosEven = 0xB
  private val idTrigCosOdd = 0xC
  private val idSoftplusEven = 0xD
  private val idSoftplusOdd = 0xE

  private val extTrigSinEvenHit = io.Buffer_exts.enable && (extSel === idTrigSinEven.U)
  private val extTrigSinOddHit = io.Buffer_exts.enable && (extSel === idTrigSinOdd.U)
  private val extTrigCosEvenHit = io.Buffer_exts.enable && (extSel === idTrigCosEven.U)
  private val extTrigCosOddHit = io.Buffer_exts.enable && (extSel === idTrigCosOdd.U)
  private val extSoftplusEvenHit = io.Buffer_exts.enable && (extSel === idSoftplusEven.U)
  private val extSoftplusOddHit = io.Buffer_exts.enable && (extSel === idSoftplusOdd.U)

  private def gateLutPort(port: SramRwIO, block: Bool, dataWidth: Int, addrWidth: Int): SramRwIO = {
    val gated = Wire(new SramRwIO(dataWidth = dataWidth, addrWidth = addrWidth))
    gated.enable := port.enable && !block
    gated.addr := port.addr
    gated.write := port.write && !block
    gated.dataIn := port.dataIn
    gated.bweb := port.bweb
    port.dataOut := gated.dataOut
    gated
  }

  private def padTo128(data: UInt, width: Int): UInt = {
    if (width == 128) data else Cat(0.U((128 - width).W), data)
  }

  // Shared engines
  val lut = Module(new LutTop(
    numSequencers = numCores,
    globalDepth = globalDepth,
    localDepth = localDepth,
    tempDepth = tempDepth,
    sramDataWidth = sramDataWidth,
    dimWidth = dimWidth
  ))

  val reduce = Module(new ReduceTreeTop(
    numSequencers = numCores,
    globalDepth = globalDepth,
    localDepth = localDepth,
    tempDepth = tempDepth,
    sramDataWidth = sramDataWidth,
    elemCountWidth = elemCountWidth,
    reqIdWidth = reqIdWidth,
    sigWidth = sigWidth,
    expWidth = expWidth,
    ieeeCompliance = ieeeCompliance
  ))

  val absEngine = Module(new AbsEngineTop(
    numSequencers = numCores,
    globalDepth = globalDepth,
    localDepth = localDepth,
    tempDepth = tempDepth,
    wordWidth = sramDataWidth,
    dimWidth = dimWidth,
    reqIdWidth = reqIdWidth
  ))

  val dataLayout = Module(new DataLayoutEngineTop(
    numSequencers = numCores,
    globalDepth = globalDepth,
    localDepth = localDepth,
    tempDepth = tempDepth,
    inWordWidth = sramDataWidth,
    outWordWidth = sramDataWidth,
    valueWidth = fpw,
    dimWidth = dimWidth,
    reqIdWidth = reqIdWidth
  ))

  // LUT SRAMs (Trig / Softplus) + external access
  private val trigAddrWidth = log2Ceil(128)
  private val softplusAddrWidth = log2Ceil(256)

  val trigSinEvenSram = Module(new LocalSram(depth = 128, dataWidth = 16, bankWidth = 16))
  val trigSinOddSram  = Module(new LocalSram(depth = 128, dataWidth = 16, bankWidth = 16))
  val trigCosEvenSram = Module(new LocalSram(depth = 128, dataWidth = 16, bankWidth = 16))
  val trigCosOddSram  = Module(new LocalSram(depth = 128, dataWidth = 16, bankWidth = 16))
  val softplusEvenSram = Module(new LocalSram(depth = 256, dataWidth = 32, bankWidth = 32))
  val softplusOddSram  = Module(new LocalSram(depth = 256, dataWidth = 32, bankWidth = 32))

  val extTrigSinEven = makeExtPort(idTrigSinEven, 16, trigAddrWidth)
  val extTrigSinOdd  = makeExtPort(idTrigSinOdd, 16, trigAddrWidth)
  val extTrigCosEven = makeExtPort(idTrigCosEven, 16, trigAddrWidth)
  val extTrigCosOdd  = makeExtPort(idTrigCosOdd, 16, trigAddrWidth)
  val extSoftplusEven = makeExtPort(idSoftplusEven, 32, softplusAddrWidth)
  val extSoftplusOdd  = makeExtPort(idSoftplusOdd, 32, softplusAddrWidth)

  val lutTrigSinEven = gateLutPort(lut.io.trigSinEvenSram, extTrigSinEvenHit, 16, trigAddrWidth)
  val lutTrigSinOdd  = gateLutPort(lut.io.trigSinOddSram, extTrigSinOddHit, 16, trigAddrWidth)
  val lutTrigCosEven = gateLutPort(lut.io.trigCosEvenSram, extTrigCosEvenHit, 16, trigAddrWidth)
  val lutTrigCosOdd  = gateLutPort(lut.io.trigCosOddSram, extTrigCosOddHit, 16, trigAddrWidth)
  val lutSoftplusEven = gateLutPort(lut.io.softplusEvenSram, extSoftplusEvenHit, 32, softplusAddrWidth)
  val lutSoftplusOdd  = gateLutPort(lut.io.softplusOddSram, extSoftplusOddHit, 32, softplusAddrWidth)

  connectSramArb(trigSinEvenSram.io, Seq(lutTrigSinEven, extTrigSinEven), "trig_sin_even")
  connectSramArb(trigSinOddSram.io,  Seq(lutTrigSinOdd, extTrigSinOdd), "trig_sin_odd")
  connectSramArb(trigCosEvenSram.io, Seq(lutTrigCosEven, extTrigCosEven), "trig_cos_even")
  connectSramArb(trigCosOddSram.io,  Seq(lutTrigCosOdd, extTrigCosOdd), "trig_cos_odd")
  connectSramArb(softplusEvenSram.io, Seq(lutSoftplusEven, extSoftplusEven), "softplus_even")
  connectSramArb(softplusOddSram.io,  Seq(lutSoftplusOdd, extSoftplusOdd), "softplus_odd")

  // LA cores
  val cmdSeqs = Seq.fill(numCores) {
    Module(new CmdSeq(
      fifoDepth = fifoDepth,
      addrWidth = addrWidth,
      dimWidth = dimWidth,
      reqIdWidth = reqIdWidth,
      fpw = fpw,
      elemCountWidth = elemCountWidth
    ))
  }

  val macs = Seq.fill(numCores) {
    Module(new MacArrayTop(
      nArray = 16,
      globalDepth = globalDepth,
      localDepth = localDepth,
      tempDepth = tempDepth,
      sramDataWidth = sramDataWidth,
      dimWidth = dimWidth,
      sigWidth = sigWidth,
      expWidth = expWidth,
      ieeeCompliance = ieeeCompliance,
      enUbrFlag = enUbrFlag
    ))
  }

  val localSrams = Seq.fill(numCores) {
    Module(new LocalSram(depth = localDepth, dataWidth = sramDataWidth, bankWidth = 128))
  }

  val tempBufs = Seq.fill(numCores) {
    Module(new TempBuffer(depth = tempDepth, dataWidth = sramDataWidth, bankDepth = tempDepth / 4))
  }

  private val doneCountReg = RegInit(VecInit(Seq.fill(numCores)(0.U(32.W))))
  private val lastDoneReg = RegInit(VecInit(Seq.fill(numCores)(0.U(32.W))))
  private val lastDoneCycleReg = RegInit(VecInit(Seq.fill(numCores)(0.U(32.W))))
  private val overflowReg = RegInit(VecInit(Seq.fill(numCores)(false.B)))
  private val cycleCounterReg = RegInit(VecInit(Seq.fill(numCores)(0.U(32.W))))
  private val activePrevReg = RegInit(VecInit(Seq.fill(numCores)(false.B)))
  private val allDoneVec = Wire(Vec(numCores, Bool()))
  private val doneSignalVec = Wire(Vec(numCores, Bool()))

  // Connect command sequencers to shared engines and per-core MACs
  for (i <- 0 until numCores) {
    val cs = cmdSeqs(i)
    val mac = macs(i)

    // MAC interface
    mac.io.opSel := cs.io.mac.opSel
    mac.io.start := cs.io.mac.start
    mac.io.nRows := cs.io.mac.nRows
    mac.io.mCols := cs.io.mac.mCols
    mac.io.kDim := cs.io.mac.kDim
    mac.io.alpha := cs.io.mac.alpha
    mac.io.baseA := cs.io.mac.baseA
    mac.io.baseB := cs.io.mac.baseB
    mac.io.baseC := cs.io.mac.baseC
    mac.io.baseASramId := cs.io.mac.baseASramId
    mac.io.baseBSramId := cs.io.mac.baseBSramId
    mac.io.baseCSramId := cs.io.mac.baseCSramId
    cs.io.mac.busy := mac.io.busy
    cs.io.mac.done := mac.io.done

    // Abs engine
    absEngine.io.cmdReq(i).valid := cs.io.absCmdReq.valid
    absEngine.io.cmdReq(i).bits.srcSramId := cs.io.absCmdReq.bits.srcSramId
    absEngine.io.cmdReq(i).bits.dstSramId := cs.io.absCmdReq.bits.dstSramId
    absEngine.io.cmdReq(i).bits.srcBase := cs.io.absCmdReq.bits.srcBase
    absEngine.io.cmdReq(i).bits.dstBase := cs.io.absCmdReq.bits.dstBase
    absEngine.io.cmdReq(i).bits.rows := cs.io.absCmdReq.bits.rows
    absEngine.io.cmdReq(i).bits.cols := cs.io.absCmdReq.bits.cols
    absEngine.io.cmdReq(i).bits.reqId := cs.io.absCmdReq.bits.reqId
    cs.io.absCmdReq.ready := absEngine.io.cmdReq(i).ready

    cs.io.absCmdRsp.valid := absEngine.io.cmdRsp(i).valid
    cs.io.absCmdRsp.bits.reqId := absEngine.io.cmdRsp(i).bits.reqId
    cs.io.absCmdRsp.bits.srcSramId := absEngine.io.cmdRsp(i).bits.srcSramId
    cs.io.absCmdRsp.bits.dstSramId := absEngine.io.cmdRsp(i).bits.dstSramId
    cs.io.absCmdRsp.bits.srcBase := absEngine.io.cmdRsp(i).bits.srcBase
    cs.io.absCmdRsp.bits.dstBase := absEngine.io.cmdRsp(i).bits.dstBase
    cs.io.absCmdRsp.bits.rows := absEngine.io.cmdRsp(i).bits.rows
    cs.io.absCmdRsp.bits.cols := absEngine.io.cmdRsp(i).bits.cols
    cs.io.absCmdRsp.bits.done := absEngine.io.cmdRsp(i).bits.done
    absEngine.io.cmdRsp(i).ready := cs.io.absCmdRsp.ready

    // Reduce tree
    reduce.io.cmdReq(i).valid := cs.io.reduceCmdReq.valid
    reduce.io.cmdReq(i).bits.mode := cs.io.reduceCmdReq.bits.mode
    reduce.io.cmdReq(i).bits.srcSramId := cs.io.reduceCmdReq.bits.srcSramId
    reduce.io.cmdReq(i).bits.baseAddr := cs.io.reduceCmdReq.bits.baseAddr
    reduce.io.cmdReq(i).bits.elemCount := cs.io.reduceCmdReq.bits.elemCount
    reduce.io.cmdReq(i).bits.reqId := cs.io.reduceCmdReq.bits.reqId
    cs.io.reduceCmdReq.ready := reduce.io.cmdReq(i).ready

    cs.io.reduceCmdRsp.valid := reduce.io.cmdRsp(i).valid
    cs.io.reduceCmdRsp.bits.reqId := reduce.io.cmdRsp(i).bits.reqId
    cs.io.reduceCmdRsp.bits.mode := reduce.io.cmdRsp(i).bits.mode
    cs.io.reduceCmdRsp.bits.srcSramId := reduce.io.cmdRsp(i).bits.srcSramId
    cs.io.reduceCmdRsp.bits.baseAddr := reduce.io.cmdRsp(i).bits.baseAddr
    cs.io.reduceCmdRsp.bits.elemCount := reduce.io.cmdRsp(i).bits.elemCount
    cs.io.reduceCmdRsp.bits.resultValue := reduce.io.cmdRsp(i).bits.resultValue
    cs.io.reduceCmdRsp.bits.resultIndex := reduce.io.cmdRsp(i).bits.resultIndex
    reduce.io.cmdRsp(i).ready := cs.io.reduceCmdRsp.ready

    // LUT
    lut.io.cmdReq(i).valid := cs.io.lutCmdReq.valid
    lut.io.cmdReq(i).bits.funcSel := cs.io.lutCmdReq.bits.funcSel
    lut.io.cmdReq(i).bits.trigSel := cs.io.lutCmdReq.bits.trigSel
    lut.io.cmdReq(i).bits.srcSramId := cs.io.lutCmdReq.bits.srcSramId
    lut.io.cmdReq(i).bits.dstSramId := cs.io.lutCmdReq.bits.dstSramId
    lut.io.cmdReq(i).bits.srcBase := cs.io.lutCmdReq.bits.srcBase
    lut.io.cmdReq(i).bits.dstBase := cs.io.lutCmdReq.bits.dstBase
    lut.io.cmdReq(i).bits.rows := cs.io.lutCmdReq.bits.rows
    lut.io.cmdReq(i).bits.cols := cs.io.lutCmdReq.bits.cols
    cs.io.lutCmdReq.ready := lut.io.cmdReq(i).ready

    cs.io.lutCmdRsp.valid := lut.io.cmdRsp(i).valid
    cs.io.lutCmdRsp.bits.done := lut.io.cmdRsp(i).bits.done
    lut.io.cmdRsp(i).ready := cs.io.lutCmdRsp.ready

    // Data layout
    dataLayout.io.cmdReq(i).valid := cs.io.dataLayoutCmdReq.valid
    dataLayout.io.cmdReq(i).bits.mode := cs.io.dataLayoutCmdReq.bits.mode
    dataLayout.io.cmdReq(i).bits.srcSramId := cs.io.dataLayoutCmdReq.bits.srcSramId
    dataLayout.io.cmdReq(i).bits.dstSramId := cs.io.dataLayoutCmdReq.bits.dstSramId
    dataLayout.io.cmdReq(i).bits.srcBase := cs.io.dataLayoutCmdReq.bits.srcBase
    dataLayout.io.cmdReq(i).bits.srcRows := cs.io.dataLayoutCmdReq.bits.srcRows
    dataLayout.io.cmdReq(i).bits.srcCols := cs.io.dataLayoutCmdReq.bits.srcCols
    dataLayout.io.cmdReq(i).bits.dstBase := cs.io.dataLayoutCmdReq.bits.dstBase
    dataLayout.io.cmdReq(i).bits.dstRows := cs.io.dataLayoutCmdReq.bits.dstRows
    dataLayout.io.cmdReq(i).bits.dstCols := cs.io.dataLayoutCmdReq.bits.dstCols
    dataLayout.io.cmdReq(i).bits.offsetRow := cs.io.dataLayoutCmdReq.bits.offsetRow
    dataLayout.io.cmdReq(i).bits.offsetCol := cs.io.dataLayoutCmdReq.bits.offsetCol
    dataLayout.io.cmdReq(i).bits.reqId := cs.io.dataLayoutCmdReq.bits.reqId
    cs.io.dataLayoutCmdReq.ready := dataLayout.io.cmdReq(i).ready

    cs.io.dataLayoutCmdRsp.valid := dataLayout.io.cmdRsp(i).valid
    cs.io.dataLayoutCmdRsp.bits.mode := dataLayout.io.cmdRsp(i).bits.mode
    cs.io.dataLayoutCmdRsp.bits.srcSramId := dataLayout.io.cmdRsp(i).bits.srcSramId
    cs.io.dataLayoutCmdRsp.bits.dstSramId := dataLayout.io.cmdRsp(i).bits.dstSramId
    cs.io.dataLayoutCmdRsp.bits.srcBase := dataLayout.io.cmdRsp(i).bits.srcBase
    cs.io.dataLayoutCmdRsp.bits.srcRows := dataLayout.io.cmdRsp(i).bits.srcRows
    cs.io.dataLayoutCmdRsp.bits.srcCols := dataLayout.io.cmdRsp(i).bits.srcCols
    cs.io.dataLayoutCmdRsp.bits.dstBase := dataLayout.io.cmdRsp(i).bits.dstBase
    cs.io.dataLayoutCmdRsp.bits.dstRows := dataLayout.io.cmdRsp(i).bits.dstRows
    cs.io.dataLayoutCmdRsp.bits.dstCols := dataLayout.io.cmdRsp(i).bits.dstCols
    cs.io.dataLayoutCmdRsp.bits.offsetRow := dataLayout.io.cmdRsp(i).bits.offsetRow
    cs.io.dataLayoutCmdRsp.bits.offsetCol := dataLayout.io.cmdRsp(i).bits.offsetCol
    cs.io.dataLayoutCmdRsp.bits.reqId := dataLayout.io.cmdRsp(i).bits.reqId
    cs.io.dataLayoutCmdRsp.bits.done := dataLayout.io.cmdRsp(i).bits.done
    dataLayout.io.cmdRsp(i).ready := cs.io.dataLayoutCmdRsp.ready
  }

  // Config/status regs per core (no handshake on cmdIn)
  for (i <- 0 until numCores) {
    val cs = cmdSeqs(i)

    val cmdBits = Cat(io.cmdWord(i)(2), io.cmdWord(i)(1), io.cmdWord(i)(0))
    val cmdPush = io.cmdCtrl(i)(0)

    cs.io.cmdIn.bits := cmdBits
    cs.io.cmdIn.valid := cmdPush

    when(cmdPush && cs.io.fifoFull) {
      overflowReg(i) := true.B
    }

    val active = cs.io.activeValid
    val activePrev = activePrevReg(i)
    val activeRise = active && !activePrev
    val cycleCount = cycleCounterReg(i)
    val cycleNext = Mux(activeRise, 1.U, Mux(active, cycleCount + 1.U, cycleCount))

    when(activeRise) {
      cycleCounterReg(i) := 1.U
    }.elsewhen(active) {
      cycleCounterReg(i) := cycleCount + 1.U
    }.otherwise {
      cycleCounterReg(i) := cycleCount
    }
    activePrevReg(i) := active

    doneSignalVec(i) := cs.io.doneValid

    when(cs.io.doneValid) {
      doneCountReg(i) := doneCountReg(i) + 1.U
      lastDoneReg(i) := Cat(
        0.U(11.W),
        cs.io.illegalCmd,
        cs.io.doneGroupEnd,
        cs.io.doneSubop,
        cs.io.doneOpcode,
        cs.io.doneCmdId
      )
      lastDoneCycleReg(i) := cycleCounterReg(i)
    }

    val allDone = cs.io.fifoEmpty && cs.io.idle
    allDoneVec(i) := allDone
    val fifoCountPadded = Wire(UInt(8.W))
    fifoCountPadded := cs.io.fifoCount

    io.cmdStatus(i) := Cat(
      0.U(16.W),
      fifoCountPadded,
      0.U(2.W),
      overflowReg(i),
      allDone,
      cs.io.idle,
      cs.io.busy,
      cs.io.fifoEmpty,
      cs.io.fifoFull
    )

    io.doneCount(i) := doneCountReg(i)
    io.lastDone(i) := lastDoneReg(i)
    io.lastDoneCycle(i) := lastDoneCycleReg(i)
    io.cycleRdData(i) := 0.U

    io.addReduceReg(i) := Cat(0.U(3.W), cs.io.addReduceValid, cs.io.addReduceCmdId, cs.io.addReduceValue)
    io.cmpReduceReg0(i) := Cat(0.U(3.W), cs.io.cmpReduceValid, cs.io.cmpReduceCmdId, cs.io.cmpReduceValue)
    io.cmpReduceReg1(i) := Cat(0.U(20.W), cs.io.cmpReduceIndex)
  }

  // Global SRAM
  val globalSram = Module(new GlobalSram(depth = globalDepth, dataWidth = sramDataWidth, bankWidth = 128))

  val reduceGlobalClient = reduceSramToClient(reduce.io.globalSram, sramDataWidth, addrWidth)
  val extGlobal = makeExtPort(idGlobal, sramDataWidth, addrWidth)
  val globalClients = macs.map(_.io.globalSram) ++ Seq(
    lut.io.globalSram,
    absEngine.io.globalSram,
    dataLayout.io.globalSram,
    reduceGlobalClient,
    extGlobal
  )
  connectSramArb(globalSram.io, globalClients, "global")

  // Local + temp SRAMs per core
  val reduceLocalClient = reduceSramToClient(reduce.io.localSram, sramDataWidth, localAddrWidth)
  val reduceTempClient = reduceSramToClient(reduce.io.tempSram, sramDataWidth, tempAddrWidth)
  val localIds = Seq(idLocal0, idLocal1, idLocal2, idLocal3)
  val tempIds = Seq(idTemp0, idTemp1, idTemp2, idTemp3)
  val extLocalPorts = localIds.take(numCores).map(id => makeExtPort(id, sramDataWidth, localAddrWidth))
  val extTempPorts = tempIds.take(numCores).map(id => makeExtPort(id, sramDataWidth, tempAddrWidth))

  for (i <- 0 until numCores) {
    val localClients = collection.mutable.ArrayBuffer[SramRwIO](macs(i).io.localSram)
    val tempClients = collection.mutable.ArrayBuffer[SramRwIO](macs(i).io.tempSram)

    if (i == sharedCoreIdx) {
      localClients += lut.io.localSram
      localClients += absEngine.io.localSram
      localClients += dataLayout.io.localSram
      localClients += reduceLocalClient

      tempClients += lut.io.tempSram
      tempClients += absEngine.io.tempSram
      tempClients += dataLayout.io.tempSram
      tempClients += reduceTempClient
    }

    localClients += extLocalPorts(i)
    connectSramArb(localSrams(i).io, localClients.toSeq, s"local_$i")

    tempClients += extTempPorts(i)
    connectSramArb(tempBufs(i).io, tempClients.toSeq, s"temp_$i")
  }

  // External buffer read mux (selected by address[14:11])
  val readDataPairs = collection.mutable.ArrayBuffer[(UInt, UInt)]()
  readDataPairs += (idGlobal.U -> padTo128(extGlobal.dataOut, sramDataWidth))

  for (i <- 0 until numCores) {
    readDataPairs += (localIds(i).U -> padTo128(extLocalPorts(i).dataOut, sramDataWidth))
    readDataPairs += (tempIds(i).U -> padTo128(extTempPorts(i).dataOut, sramDataWidth))
  }

  readDataPairs += (idTrigSinEven.U -> padTo128(extTrigSinEven.dataOut, 16))
  readDataPairs += (idTrigSinOdd.U  -> padTo128(extTrigSinOdd.dataOut, 16))
  readDataPairs += (idTrigCosEven.U -> padTo128(extTrigCosEven.dataOut, 16))
  readDataPairs += (idTrigCosOdd.U  -> padTo128(extTrigCosOdd.dataOut, 16))
  readDataPairs += (idSoftplusEven.U -> padTo128(extSoftplusEven.dataOut, 32))
  readDataPairs += (idSoftplusOdd.U  -> padTo128(extSoftplusOdd.dataOut, 32))

  io.Buffer_exts.readData := MuxLookup(extSel, 0.U(128.W))(readDataPairs.toSeq)

  // Status outputs
  io.engineStatus := Cat(
    0.U(28.W),
    dataLayout.io.busy,
    lut.io.busy,
    reduce.io.busy,
    absEngine.io.busy
  )
  io.allDoneReg := Cat(0.U((32 - numCores).W), allDoneVec.asUInt)
  io.done_signal := Cat(0.U((32 - numCores).W), doneSignalVec.asUInt)
  io.spareOut1 := 0.U
}
