import _root_.circt.stage.ChiselStage
import java.nio.charset.StandardCharsets
import java.nio.file.{Files, Paths}

object GenDexMPCCoreTop extends App {
  val sv = ChiselStage.emitSystemVerilog(
    gen = new DexMPCCoreTop(),
    firtoolOpts = Array(
      "--strip-debug-info"
    )
  )
  Files.write(
    Paths.get("E:\\workspace\\Chisel_workspace\\DexMPC\\top_connect\\gen\\DexMPCCoreTop.sv"),
    sv.getBytes(StandardCharsets.UTF_8)
  )
}
