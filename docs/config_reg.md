# DexMPCCoreTop Config Registers

All registers are 32-bit. Vectored regs are indexed by core ID (0..numCores-1).

## Input Registers

### cmdWord[core][word]
- word0 = cmdWord[core][0] : cmd[31:0]
- word1 = cmdWord[core][1] : cmd[63:32]
- word2 = cmdWord[core][2] : cmd[95:64]

### cmdCtrl[core]
- [0] cmd_push
  - When 1, this cycle's cmdWord is written into the FIFO (no external handshake).
  - If FIFO is full, the command is dropped and cmdStatus[core].overflow is set.
- [31:1] reserved
- Frontend behavior depends on `is_loop[0]`
  - If `is_loop[0] = 0`, the raw regbank `cmdCtrl[core]` is edge-detected before leaving the frontend
  - Only a raw transition from `0` to `1` generates a 1-cycle pulse on the outgoing `cmdCtrl[core]`
  - After that pulse, the outgoing `cmdCtrl[core]` returns to `0`
  - If `is_loop[0] = 1`, the raw regbank `cmdCtrl[core]` is passed through directly
  - In non-loop mode (`is_loop[0] = 0`), do not perform read/write test traffic on `cmdCtrl[core]`

### cycleRdAddr[core]
- [reqIdWidth-1:0] reserved (no function; cycle regFile removed)
- [31:reqIdWidth] reserved

### spareIn0
- [31:0] reserved

### spareIn1
- [31:0] reserved

### is_loop
- Frontend-only config register
- Internal register index = `63`
- Default reset value = `0`
- Not forwarded into `DexMPCCoreBackend` or `DexMPCCoreTop`
- [0] mode select
  - `0`: non-loop mode
    - outgoing `cmdCtrl[core]` uses 0->1 edge detection and becomes a 1-cycle pulse
  - `1`: loop mode
    - outgoing `cmdCtrl[core]` directly follows the raw regbank `cmdCtrl[core]`
- [31:1] reserved
- If loop mode is needed, software must write `is_loop = 32'h0000_0001` first during initialization

## Output Registers

### cmdStatus[core]
- [0] fifo_full
- [1] fifo_empty
- [2] busy
- [3] idle
- [4] all_done (fifo_empty && idle)
- [5] overflow (sticky: set when cmd_push while fifo_full)
- [7:6] reserved
- [15:8] fifo_count (zero-extended)
- [31:16] reserved

### doneCount[core]
- [31:0] total completed commands (includes illegal commands)

### lastDone[core]
- [11:0] last_done_cmd_id
- [14:12] last_done_opcode
- [18:15] last_done_subop
- [19] last_done_group_end
- [20] last_done_illegal
- [31:21] reserved

### lastDoneCycle[core]
- [31:0] cycle count for the last completed command

### cycleRdData[core]
- [31:0] reserved (reads as 0; cycle regFile removed)

### addReduceReg[core]
- [15:0] add_reduce_value (fpw)
- [27:16] add_reduce_cmd_id
- [28] add_reduce_valid
- [31:29] reserved

### cmpReduceReg0[core]
- [15:0] cmp_reduce_value (fpw)
- [27:16] cmp_reduce_cmd_id
- [28] cmp_reduce_valid
- [31:29] reserved

### cmpReduceReg1[core]
- [11:0] cmp_reduce_index
- [31:12] reserved

### engineStatus
- [0] abs_busy
- [1] reduce_busy
- [2] lut_busy
- [3] datalayout_busy
- [31:4] reserved

### allDoneReg
- [numCores-1:0] per-core all_done (bit0=core0, bit1=core1, ...)
- [31:numCores] reserved

### spareOut0
- [31:0] reserved

### spareOut1
- [31:0] reserved
