# DexMPC Address Area (AXI -> Acorn -> Config/SRAM)

## 总览
- AXI 地址宽度: 17 bits（2 + 15）
- 低层 Acorn 地址仍使用同样宽度。
- 顶层分流规则（来自 `DexMPCCoreFrontend` / `DexMPCCoreAcornDemux`）：
  - `addr[16:15] == 2'b00` -> **CONFIG 区**
  - `addr[16:15] == 2'b01` -> **SRAM 区**
  - 其它取值目前会落入 CONFIG（等同 `00`，保留不用）

---

## CONFIG 区（addr[16:15] = 2'b00）
- 仅使用地址低 6 位：`reg_idx = addr[5:0]`
- 共 58 个 32-bit reg（索引 0..57）
- 读写行为：
  - `reg_idx < 22` 为 **可写输入寄存器**
  - `reg_idx >= 22` 为 **只读输出寄存器**（由后端回写）
  - 读数据出现在 `rdata[31:0]`，高位补零
  - 写仅使用 `wdata[31:0]` 和 `wmask[3:0]`

### 输入寄存器（可写）
- `0..11` : `cmdWord[core][word]`
  - `idx = core*3 + word`
  - core=0..3, word=0..2
- `12..15` : `cmdCtrl[core]`
  - `idx = 12 + core`
- `16..19` : `cycleRdAddr[core]`
  - `idx = 16 + core`
- `20` : `spareIn0`
- `21` : `spareIn1`

### 输出寄存器（只读）
- `22..25` : `cmdStatus[core]`
- `26..29` : `doneCount[core]`
- `30..33` : `lastDone[core]`
- `34..37` : `lastDoneCycle[core]`
- `38..41` : `cycleRdData[core]`
- `42..45` : `addReduceReg[core]`
- `46..49` : `cmpReduceReg0[core]`
- `50..53` : `cmpReduceReg1[core]`
- `54` : `engineStatus`
- `55` : `allDoneReg`
- `56` : `spareOut0`
- `57` : `spareOut1`

> 以上 reg 的字段含义详见 `docs/config_reg.md`

---

## SRAM 区（addr[16:15] = 2'b01）
- 使用低 15 位直接透传给 `Buffer_exts`：
  - `mem_id = addr[14:11]`
  - `word_addr = addr[10:0]`
  - 对 Temp Buffer（depth 896）仅使用 `word_addr[9:0]`，`word_addr[10]` 需为 0
- 数据宽度 128bit；对小位宽 SRAM（16/32）只使用低位写入 / 低位掩码，读回 0 扩展到 128bit。
- 具体 Memory ID 映射如下（与 `MemoryAccess.md` 一致）：

### Memory ID 映射（addr[14:11]）
- `0x0` -> Global SRAM (depth 2048, width 128)
- `0x1` -> Local SRAM core0 (depth 512, width 128)
- `0x2` -> Local SRAM core1 (depth 512, width 128)
- `0x3` -> Local SRAM core2 (depth 512, width 128)
- `0x4` -> Local SRAM core3 (depth 512, width 128)
- `0x5` -> Temp Buffer core0 (depth 896, width 128)
- `0x6` -> Temp Buffer core1 (depth 896, width 128)
- `0x7` -> Temp Buffer core2 (depth 896, width 128)
- `0x8` -> Temp Buffer core3 (depth 896, width 128)
- `0x9` -> TrigLut sin even (depth 128, width 16)
- `0xA` -> TrigLut sin odd  (depth 128, width 16)
- `0xB` -> TrigLut cos even (depth 128, width 16)
- `0xC` -> TrigLut cos odd  (depth 128, width 16)
- `0xD` -> Softplus even    (depth 256, width 32)
- `0xE` -> Softplus odd     (depth 256, width 32)
- `0xF` -> Reserved

---

## LUT / Softplus Narrow SRAM Notes

- `TrigLut` SRAM width is `16 bit`
- `Softplus` SRAM width is `32 bit`
- External `Buffer_exts` interface remains `128 bit`

Current external-access behavior:

- Write path
  - `TrigLut` only uses `writeData[15:0]` and `bweb[15:0]`
  - `Softplus` only uses `writeData[31:0]` and `bweb[31:0]`
- Read path
  - `TrigLut` returns valid data in `readData[15:0]`, upper `112 bit` are zero
  - `Softplus` returns valid data in `readData[31:0]`, upper `96 bit` are zero

Equivalent packed readback format:

- `TrigLut`: `readData = {112'h0, data[15:0]}`
- `Softplus`: `readData = {96'h0, data[31:0]}`

---

## Frontend-only `is_loop` Register

- A frontend-only config register is added at internal index `63`
- Register name: `is_loop`
- Width: `32 bit`
- Reset default: `0`
- It is not forwarded into backend or coreTop

Behavior:

- `is_loop[0] = 0`
  - non-loop mode
  - raw `cmdCtrl[core]` values stored in the regbank are edge-detected
  - only a raw transition from `0` to `1` generates a 1-cycle outgoing `cmdCtrl[core]` pulse
- `is_loop[0] = 1`
  - loop mode
  - raw regbank `cmdCtrl[core]` is passed through directly

Additional notes:

- If loop mode is needed, software must write `is_loop = 32'h0000_0001` first during initialization
- When `is_loop[0] = 0`, do not perform read/write test traffic on `cmdCtrl[core]`
- Indices `58..62` are currently reserved/unused

---

## 备注
- 当前地址空间只定义 CONFIG 与 SRAM 两个区域。
- `addr[16:15] = 2'b10 / 2'b11` 目前会落入 CONFIG 分支（建议保留不用）。
