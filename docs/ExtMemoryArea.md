# DexMPC 外部访问地址说明

本文档基于 `address_area.md`，说明从外界访问 DexMPC 时应使用的地址。

## 当前总原则

- 外部地址空间按 `8 Byte` 对齐
- 所有外部访问地址都满足：
  - `addr[2:0] = 3'b000`
- 当前 DexMPC 基地址为：
  - `BASE_DEXMPC_ADDR = 0x0000_0000`
- 因此当前：
  - `abs_addr = ext_addr`

也就是说，现在“绝对地址”和“DexMPC 外部偏移地址”是同一个值。

---

## 外部地址空间

- 当前 DexMPC 使用的外部地址窗口为：
  - `[0x00000, 0x80000)`
- 其中：
  - `0x00000 ~ 0x3FFFF`：CONFIG 区
  - `0x40000 ~ 0x7FFFF`：SRAM 区

在 `DexMPCCoreFrontend` / `DexMPCCoreAcornDemux` 中，译码规则为：

- `addr[19:18] == 2'b00` -> CONFIG
- `addr[19:18] == 2'b01` -> SRAM
- `addr[19:18] == 2'b10 / 2'b11` -> 当前不建议使用

---

## CONFIG 访问

### 地址公式

- 寄存器索引：
  - `reg_idx`
- 外部地址：
  - `cfg_addr = reg_idx << 3`

### 字段解释

- `addr[8:3] = reg_idx`
- `addr[2:0] = 3'b000`

也就是说，`DexMPCCoreConfigRegBank` 实际会把外部 config 地址右移 3 位后，再作为内部寄存器编号访问。

### 例子

- `reg0`
  - `cfg_addr = 0x000`
- `reg1`
  - `cfg_addr = 0x008`
- `reg12`
  - `cfg_addr = 0x060`
- `reg20`
  - `cfg_addr = 0x0A0`
- `reg55`
  - `cfg_addr = 0x1B8`

---

## SRAM 访问

### 旧内部地址编码

原来的 SRAM 编码为：

- `old_sram_addr = 0x8000 + (mem_id << 11) + word_addr`

其中：

- `mem_id = addr[14:11]`
- `word_addr = addr[10:0]`

### 当前外部地址公式

- 外部 SRAM 地址：
  - `sram_addr = old_sram_addr << 3`
- 即：
  - `sram_addr = (0x8000 + (mem_id << 11) + word_addr) << 3`

### 地址字段解释

- `addr[19:18] = 2'b01`
- `addr[17:14] = mem_id`
- `addr[13:3] = word_addr`
- `addr[2:0] = 3'b000`

也就是说，`DexMPCBufferGate` 会把外部 SRAM 地址右移 3 位，再作为内部 `BufferAccess` 地址访问。

### SRAM 地址范围

- 最低 SRAM 地址：
  - `0x8000 << 3 = 0x40000`
- 最高 SRAM 地址：
  - `0xFFFF << 3 = 0x7FFF8`

因此 SRAM 区完整落在：

- `0x40000 ~ 0x7FFF8`

这与当前 DexMPC 外部地址窗口 `[0x00000, 0x80000)` 是一致的。

### 例子

- Global SRAM, `mem_id = 0`, `word_addr = 5`
  - `old_sram_addr = 0x8005`
  - `sram_addr = 0x40028`

- Global SRAM, `mem_id = 0`, `word_addr = 6`
  - `old_sram_addr = 0x8006`
  - `sram_addr = 0x40030`

- Local SRAM core0, `mem_id = 1`, `word_addr = 0`
  - `old_sram_addr = 0x8800`
  - `sram_addr = 0x44000`

---

## 调试时建议直接看什么

- CONFIG 实际寄存器编号：
  - `reg_idx = addr[8:3]`
- SRAM 实际内部地址：
  - `buf_addr = addr[17:3]`
- 任意外部访问都应满足：
  - `addr[2:0] == 3'b000`

---

## 对应 TB helper

后续接入 chip 顶层外设 testbench 时，对应 helper 应保持如下含义：

- CONFIG：
  - `mpc_cfg_addr(reg_idx) = reg_idx << 3`
- SRAM：
  - `mpc_sram_addr(mem_id, word_addr) = (0x8000 + (mem_id << 11) + word_addr) << 3`

因此例如：

- `mpc_cfg_addr(0) = 0x000`
- `mpc_cfg_addr(1) = 0x008`
- `mpc_sram_addr(0, 5) = 0x40028`

---

## TrigLut / Softplus 窄位宽补充

虽然外部 SRAM 访问统一通过 `128 bit` 的 `Buffer_exts` 接口进行，但以下几块 SRAM 本身不是 `128 bit`：

- `TrigLut` 四块 SRAM：`16 bit`
  - `0x9` / `0xA` / `0xB` / `0xC`
- `Softplus` 两块 SRAM：`32 bit`
  - `0xD` / `0xE`

因此外部访问时需要注意：

- 写 `TrigLut` 时，真正写入的只有低 `16 bit`
  - 使用 `writeData[15:0]`
  - `bweb` 也只看低 `16 bit`
- 写 `Softplus` 时，真正写入的只有低 `32 bit`
  - 使用 `writeData[31:0]`
  - `bweb` 也只看低 `32 bit`

- 读 `TrigLut` 时：
  - 返回值低 `16 bit` 是有效数据
  - 高 `112 bit` 全部补 `0`
- 读 `Softplus` 时：
  - 返回值低 `32 bit` 是有效数据
  - 高 `96 bit` 全部补 `0`

可按下面方式理解外部读回值：

- `TrigLut`：
  - `readData = {112'h0, lut_data[15:0]}`
- `Softplus`：
  - `readData = {96'h0, lut_data[31:0]}`

---

## Frontend-only `is_loop` Register

- `is_loop` is a frontend-only config register
- Internal register index is `63`
- Its external config address is:
  - `cfg_addr = 63 << 3 = 0x1F8`
- Width is `32 bit`
- Reset default is `0`

Function:

- If `is_loop[0] = 0`
  - outgoing `cmdCtrl[core]` does not directly equal the raw regbank `cmdCtrl[core]`
  - instead, the frontend only emits a 1-cycle pulse when raw `cmdCtrl[core]` changes from `0` to `1`
- If `is_loop[0] = 1`
  - outgoing `cmdCtrl[core]` directly follows the raw regbank `cmdCtrl[core]`

Important reminders:

- If loop mode is required, software must write `is_loop = 32'h0000_0001` first during initialization
- When `is_loop[0] = 0`, do not perform read/write test traffic on `cmdCtrl[core]`
- Config indices `58..62` are currently reserved/unused
