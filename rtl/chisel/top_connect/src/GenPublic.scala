import chisel3._
import chisel3.util._
import _root_.circt.stage.ChiselStage
import java.nio.file.{Files, Paths}
import java.nio.charset.StandardCharsets
import chipmunk._


object GenPublic extends App {
  val sv = ChiselStage.emitSystemVerilog(
    gen = new DexMPCCore(),
    firtoolOpts = Array(
      "--strip-debug-info",
      "--disable-all-randomization"
    )
  )
  Files.write(Paths.get("E:\\workspace\\Chisel_workspace\\DexMPC\\top_connect\\gen\\DexMPCCore.sv"), sv.getBytes(StandardCharsets.UTF_8))
}
