import chisel3._
import chisel3.util._

class DecoupledRRArbIO[Cmd <: Data, Rsp <: Data](
  cmdType: Cmd,
  rspType: Rsp,
  numSeq: Int,
  seqIdWidth: Int
) extends Bundle {
  val cmdReq = Vec(numSeq, Flipped(Decoupled(cmdType.cloneType)))
  val cmdRsp = Vec(numSeq, Decoupled(rspType.cloneType))

  val coreBusy = Input(Bool())
  val coreDone = Input(Bool())

  val start = Output(Bool())
  val cmdOut = Output(cmdType.cloneType)
  val cmdSeqId = Output(UInt(seqIdWidth.W))

  val activeCmd = Output(cmdType.cloneType)
  val activeSeqId = Output(UInt(seqIdWidth.W))

  val rspIn = Input(rspType.cloneType)

  val busy = Output(Bool())
  val idle = Output(Bool())
  val status = Output(UInt(2.W)) // 0: idle, 1: running, 2: wait response consume
  val activeSequencerValid = Output(Bool())
  val activeSequencerId = Output(UInt(seqIdWidth.W))
}

class DecoupledRRArb[Cmd <: Data, Rsp <: Data](
  cmdType: Cmd,
  rspType: Rsp,
  numSeq: Int
) extends Module {
  require(numSeq > 0, "DecoupledRRArb numSeq must be > 0")

  private val seqIdWidth = math.max(1, log2Ceil(numSeq))
  val io = IO(new DecoupledRRArbIO(cmdType, rspType, numSeq, seqIdWidth))

  val reqValids = Wire(Vec(numSeq, Bool()))
  for (seq <- 0 until numSeq) {
    reqValids(seq) := io.cmdReq(seq).valid
  }

  val rrPtr = RegInit(0.U(seqIdWidth.W))
  val rotatedValids = Wire(Vec(numSeq, Bool()))
  val rotatedIdx = Wire(Vec(numSeq, UInt(seqIdWidth.W)))

  for (offset <- 0 until numSeq) {
    val sum = rrPtr + offset.U
    val wrapped = Mux(sum >= numSeq.U, sum - numSeq.U, sum)
    val idx = wrapped(seqIdWidth - 1, 0)
    rotatedValids(offset) := reqValids(idx)
    rotatedIdx(offset) := idx
  }

  val grantValid = rotatedValids.asUInt.orR
  val grantEnc = PriorityEncoder(rotatedValids.asUInt)
  val grantIdx = Mux(grantValid, rotatedIdx(grantEnc), 0.U(seqIdWidth.W))
  val grantCmd = Mux(grantValid, io.cmdReq(grantIdx).bits, 0.U.asTypeOf(cmdType))

  val activeValidReg = RegInit(false.B)
  val activeSeqReg = RegInit(0.U(seqIdWidth.W))
  val activeCmdReg = RegInit(0.U.asTypeOf(cmdType))

  val rspPendingReg = RegInit(false.B)
  val rspSeqReg = RegInit(0.U(seqIdWidth.W))
  val rspBitsReg = RegInit(0.U.asTypeOf(rspType))

  val coreReadyForStart = !activeValidReg && !rspPendingReg && !io.coreBusy && !io.coreDone
  for (seq <- 0 until numSeq) {
    io.cmdReq(seq).ready := coreReadyForStart && grantValid && (grantIdx === seq.U)
  }

  val launchFire = coreReadyForStart && grantValid

  io.start := launchFire
  io.cmdOut := grantCmd
  io.cmdSeqId := grantIdx
  io.activeCmd := activeCmdReg
  io.activeSeqId := activeSeqReg

  when(launchFire) {
    activeValidReg := true.B
    activeSeqReg := grantIdx
    activeCmdReg := grantCmd
    rrPtr := Mux(grantIdx === (numSeq - 1).U, 0.U, grantIdx + 1.U)
  }

  when(io.coreDone && activeValidReg) {
    activeValidReg := false.B
    rspPendingReg := true.B
    rspSeqReg := activeSeqReg
    rspBitsReg := io.rspIn
  }

  val rspFireVec = Wire(Vec(numSeq, Bool()))
  for (seq <- 0 until numSeq) {
    val isTargetRsp = rspPendingReg && (rspSeqReg === seq.U)
    io.cmdRsp(seq).valid := isTargetRsp
    io.cmdRsp(seq).bits := rspBitsReg
    rspFireVec(seq) := io.cmdRsp(seq).fire
  }

  when(rspFireVec.asUInt.orR) {
    rspPendingReg := false.B
  }

  val running = activeValidReg || io.coreBusy || io.coreDone
  io.busy := running || rspPendingReg
  io.idle := !io.busy
  io.status := Mux(running, 1.U(2.W), Mux(rspPendingReg, 2.U(2.W), 0.U(2.W)))

  io.activeSequencerValid := activeValidReg || rspPendingReg
  io.activeSequencerId := Mux(rspPendingReg, rspSeqReg, activeSeqReg)
}
