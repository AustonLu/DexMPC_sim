# Device Access Layer 验证记录

日期：2026-06-02

本文记录本次 SPI/debug 和 full-chip mixed 迁移到 Device 访问层后的验证结果。

## 1. 迁移范围

已从 full-chip mixed 回归迁移到软件栈 Device 访问层：

```text
verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_mixed.cpp
verification/verilator/cpp/tests/full_chip/tb_topchip_spi_mixed.cpp
```

新增测试：

```text
software_stack/tests/cpp/test_device_mixed_common.hpp
software_stack/tests/cpp/test_device_mixed_d2d.cpp
software_stack/tests/cpp/test_device_mixed_spi.cpp
```

迁移后不直接使用 `topchip::TestBase`，而是通过 `dexmpc::runtime::Device` 完成：

```text
SRAM preload
command issue
doneCount wait
reduce status readback
output SRAM readback
```

## 2. 本次修复

### 2.1 SPI stale generated model

此前 SPI SRAM readback 失败来自 stale Verilator 生成产物：

```text
build/verilator/topchiptop_legacy_spi_tb_split/VTopChipTop
```

该产物生成时 `verification/verilator/filelists/topchip.f` 尚未包含 standalone:

```text
rtl/sim_models/SramWrapperSP.sv
```

因此 Verilator 使用了 `TopChip.sv` 内嵌的 generated fallback `SramWrapperSp`。该 fallback 的仿真写 mask 使用 scalar logical negation，会破坏 128-bit SRAM write mask。当前 filelist 保证 `rtl/sim_models/SramWrapperSP.sv` 在 `TopChip.sv` 前出现，并添加了注释防止后续误删或重排。

### 2.2 Device wait_next_done 基准

迁移 mixed 测试时暴露了 `SimBackend::wait_next_done()` 的 doneCount 基准问题。

旧逻辑在调用 `wait_next_done()` 时重新读取当前 `doneCount`，但短 reduce 命令可能在 `send_instruction()` 返回后、调用 `wait_next_done()` 前已经完成。失败现象：

```text
Device mixed D2D issue reduce cid=2 issue_idx=0 group_end=0 done_count_before=0
Device mixed D2D test failed: timeout waiting for doneCount target=2 got=1
```

修复后：

- `reset()` 清零 backend 记录的 observed doneCount。
- `send_instruction()` 在下发命令前读取一次状态，记录命令发出前已观察到的 doneCount。
- `wait_next_done()` 等待 `observed_done_count + 1`，不会错过已经发生的短指令完成。
- `read_status()` 和读取 doneCount register 会同步更新 observed doneCount。

## 3. 验证结果

### 3.1 D2D smoke

```text
SimBackend D2D smoke passed at cycle 1633, done_count=0
```

### 3.2 SPI smoke

```text
SimBackend SPI smoke passed at cycle 17788, done_count=0
```

另验证当前 full-chip SPI legacy path：

```text
SPI config register smoke passed, cases=44
SPI SRAM smoke passed, cases=15 (representative memory-id sweep)
TopChipTop legacy SPI C++ test passed at core cycle 135676
```

### 3.3 Device mixed D2D full

```text
Device mixed D2D test passed at cycle 59480, cases=34, done_count=34
```

软件侧分析：

```text
overall: cases=34, pass=34, fail=0, exact=641/641, max_abs_err=0
```

### 3.4 Device mixed SPI smoke

使用：

```text
DEXMPC_DEVICE_MIXED_CASE_LIMIT=8
```

结果：

```text
Device mixed SPI test passed at cycle 538084, cases=8, done_count=8
```

软件侧分析：

```text
overall: cases=8, pass=8, fail=0, exact=335/335, max_abs_err=0
```

### 3.5 SPI full mixed 状态

SPI 34-case full mixed 可启动，并已观察到前 4 条 reduce 命令连续完成：

```text
Device mixed SPI issue reduce cid=2 issue_idx=0 group_end=0 done_count_before=0
Device mixed SPI issue reduce cid=5 issue_idx=1 group_end=0 done_count_before=1
Device mixed SPI issue reduce cid=9 issue_idx=2 group_end=0 done_count_before=2
Device mixed SPI issue reduce cid=13 issue_idx=3 group_end=0 done_count_before=3
```

本次 900 秒外层超时前未跑完整 34-case。考虑到 SPI pad-level 访问明显慢于 D2D，日常验证建议使用 8-case smoke；需要完整覆盖时再单独跑 SPI 34-case 长测。

## 4. 分析命令

D2D:

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/software_stack/device_mixed/d2d \
  --out-dir verification/results/software_stack/device_mixed/d2d
```

SPI:

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/software_stack/device_mixed/spi \
  --out-dir verification/results/software_stack/device_mixed/spi
```
