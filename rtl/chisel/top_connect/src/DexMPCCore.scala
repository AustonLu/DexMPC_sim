import chisel3._
import chipmunk._
import chipmunk.amba._

class DexMPCCore(val numCores: Int = 4) extends Module with RequireAsyncReset{
  val io = IO(new Bundle {
    val sAxi = Slave(new Axi4IO(dataWidth = DexMPCCoreFrontendConstants.AXI_DATA_WIDTH,
                                addrWidth = DexMPCCoreFrontendConstants.AXI_ADDR_WIDTH,
                                idWidth = DexMPCCoreFrontendConstants.AXI_ID_WIDTH))
    val dexState = Output(Bool())
  })

  val uFrontend = Module(new DexMPCCoreFrontend(numCores = numCores))
  val uBackend  = Module(new DexMPCCoreBackend(numCores = numCores))

  uFrontend.io.sAxi <> io.sAxi
  uBackend.io.config <> uFrontend.io.config
  uFrontend.io.allDoneReg := uBackend.io.allDoneReg

  uFrontend.io.sramAccess <> uBackend.io.Buffer_exts

  io.dexState := uBackend.io.config.out.done_signal(numCores - 1, 0).orR
}
