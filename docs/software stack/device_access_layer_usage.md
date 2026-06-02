# DexMPC 设备访问层接口说明

本文档说明当前新增的 C++ 设备访问层，包括 `SimBackend`、预留物理芯片 backend、统一 `Device` 接口，以及 D2D/SPI 的选择方式。

该层对应 `docs/software stack/software_stack_layers_simple.md` 中的：

```text
Device Driver
    |
Backend
    |
TopChip simulator / physical chip
```

当前实现文件：

```text
software_stack/include/dexmpc/runtime/device.hpp
```

当前测试文件：

```text
software_stack/tests/cpp/test_sim_backend_d2d.cpp
software_stack/tests/cpp/test_sim_backend_spi.cpp
software_stack/tests/cpp/test_device_mixed_common.hpp
software_stack/tests/cpp/test_device_mixed_d2d.cpp
software_stack/tests/cpp/test_device_mixed_spi.cpp
```

## 1. 设计目标

设备访问层的目标是把底层 TopChip simulator 或未来物理芯片封装成统一的 C++ `Device` 对象。

上层软件不直接区分：

- Verilator C++ simulator。
- 未来 FPGA/PCB/物理芯片。
- D2D。
- SPI。

上层只通过统一接口访问：

```text
reset
write_register
read_register
write_memory
read_memory
send_instruction
wait_done_count
wait_next_done
read_status
```

D2D/SPI 只在创建设备时选择，默认使用 D2D。

## 2. 当前分层

当前新增的设备访问层包含三个核心概念：

```text
Device
    |
IDeviceBackend
    |-- SimBackend
    |-- FpgaChipBackend
```

### 2.1 Device

`Device` 是上层软件使用的入口。

它不关心底层是 simulator 还是真实芯片，也不关心底层使用 D2D 还是 SPI。

典型用法：

```cpp
#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_D2D

#include "dexmpc/runtime/device.hpp"

int main(int argc, char** argv) {
    auto device = dexmpc::runtime::Device::open_sim(argc, argv);

    device.reset();
    device.write_register(reg_idx, value);
    auto value_readback = device.read_register(reg_idx);

    return 0;
}
```

### 2.2 IDeviceBackend

`IDeviceBackend` 是统一 backend interface。

它定义所有 backend 都必须支持的基本能力：

```cpp
reset()
write_register()
read_register()
write_memory()
read_memory()
send_instruction()
wait_done_count()
wait_next_done()
read_status()
```

后续无论是 simulator backend，还是真实芯片 backend，都应该实现这套接口。

### 2.3 SimBackend

`SimBackend` 是当前已经实现的 simulator backend。

它内部调用：

```text
verification/verilator/cpp/common/topchip_sim.hpp
```

也就是说：

```text
Device
    -> SimBackend
        -> topchip_sim
            -> Verilated TopChip model
```

当前 `SimBackend` 支持：

- D2D simulator。
- SPI simulator。

但一个具体可执行文件在编译时只能选择一种 simulator transport：

```cpp
#define DEX_TOPCHIP_TRANSPORT_D2D
```

或：

```cpp
#define DEX_TOPCHIP_TRANSPORT_SPI
```

这是因为 D2D 和 SPI 对应不同的 Verilator top module。

### 2.4 FpgaChipBackend

`FpgaChipBackend` 是为未来物理芯片预留的 backend。

当前只保留接口，不实现具体通信。

未来它可以连接：

```text
Python/Jupyter workflow
    -> FPGA
    -> PCB
    -> physical TopChip
```

上层接口仍然保持不变。

## 3. Backend 和 Transport 选择

### 3.1 BackendKind

当前定义：

```cpp
enum class BackendKind {
    SimModel,
    FpgaChip,
};
```

含义：

| BackendKind | 含义 |
| --- | --- |
| `SimModel` | Verilator 生成的 TopChip C++ simulator |
| `FpgaChip` | 未来 FPGA/PCB/物理芯片访问路径 |

### 3.2 Transport

当前定义：

```cpp
enum class Transport {
    D2D,
    SPI,
};
```

默认值是：

```cpp
Transport::D2D
```

也就是说，如果上层不指定，默认创建 D2D 设备。

### 3.3 DeviceOptions

设备创建参数：

```cpp
struct DeviceOptions {
    BackendKind backend = BackendKind::SimModel;
    Transport transport = Transport::D2D;
    int wait_timeout_cycles = 400000;
};
```

D2D simulator 默认创建：

```cpp
auto device = dexmpc::runtime::Device::open_sim(argc, argv);
```

显式创建 D2D simulator：

```cpp
auto device = dexmpc::runtime::Device::open_sim(
    argc,
    argv,
    dexmpc::runtime::Transport::D2D
);
```

显式创建 SPI simulator：

```cpp
auto device = dexmpc::runtime::Device::open_sim(
    argc,
    argv,
    dexmpc::runtime::Transport::SPI
);
```

通用创建方式：

```cpp
dexmpc::runtime::DeviceOptions options;
options.backend = dexmpc::runtime::BackendKind::SimModel;
options.transport = dexmpc::runtime::Transport::D2D;

auto device = dexmpc::runtime::Device::open(options, argc, argv);
```

## 4. 设备访问接口

### 4.1 reset

```cpp
device.reset();
```

作用：

- 复位 TopChip。
- 清除 loop mode。
- 刷新 simulator 内部状态。

### 4.2 register read/write

```cpp
device.write_register(reg_idx, value);
auto value = device.read_register(reg_idx);
```

这里的 `reg_idx` 是 DexMPC config register index，不是 byte address。

地址换算仍由底层 `topchip_sim` 负责。

### 4.3 SRAM read/write

写单个 128-bit word：

```cpp
dexmpc::runtime::Word128 word{
    0x01234567u,
    0x89abcdefu,
    0x13579bdfu,
    0xfedcba98u,
};

device.write_memory_word(dexsim::kMemGlobal, 0, word);
```

读单个 128-bit word：

```cpp
auto word = device.read_memory_word(dexsim::kMemGlobal, 0);
```

写连续 word：

```cpp
std::vector<dexmpc::runtime::Word128> words = ...;
device.write_memory(dexsim::kMemGlobal, base_word_addr, words);
```

读连续 word：

```cpp
auto words = device.read_memory(dexsim::kMemGlobal, base_word_addr, word_count);
```

### 4.4 发送硬件指令

```cpp
dexmpc::runtime::Cmd96 cmd = ...;
device.send_instruction(cmd);
```

注意：设备访问层只负责发送已经生成好的 `Cmd96`。

硬件指令如何从 GEMM/LUT/transpose 等算子参数生成，后续应由 `InstructionBuilder` 层负责。

也就是说：

```text
OperatorRuntime
    -> InstructionBuilder 生成 Cmd96
    -> Device::send_instruction(cmd)
```

不要在 Python 层直接拼 96-bit command。

### 4.5 等待完成

等待指定 doneCount：

```cpp
auto status = device.wait_done_count(target_done_count, timeout_cycles);
```

等待下一条完成：

```cpp
auto status = device.wait_next_done(timeout_cycles);
```

`wait_next_done()` 的语义是等待“上一次已观察到的 `doneCount`”之后的下一次完成。`SimBackend::send_instruction()` 会在下发命令前观察一次 `doneCount`，因此即使短指令在下发后、调用 `wait_next_done()` 前已经完成，也不会错过这次完成事件。

读取当前状态：

```cpp
auto status = device.read_status();
```

`StatusRegisters` 包含：

```cpp
cmd_status
done_count
last_done
add_reduce
cmp_reduce0
cmp_reduce1
engine_status
all_done
```

## 5. 编译和运行 D2D smoke test

D2D 是默认主路径，也是后续主流测试路径。

### 5.1 Verilator 生成

```sh
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTopD2dHarness \
  -f verification/verilator/filelists/topchip_top_d2d_harness.f \
  --exe software_stack/tests/cpp/test_sim_backend_d2d.cpp \
  --Mdir build/verilator/software_stack/sim_backend_d2d_smoke \
  --output-groups 0 \
  -CFLAGS "-I$PWD/software_stack/include -I$PWD/verification/verilator/cpp/common"
```

### 5.2 Make 编译

```sh
make -C build/verilator/software_stack/sim_backend_d2d_smoke \
  -f VTopChipTopD2dHarness.mk -j 8 OBJCACHE=
```

### 5.3 运行

```sh
./build/verilator/software_stack/sim_backend_d2d_smoke/VTopChipTopD2dHarness
```

预期输出类似：

```text
SimBackend D2D smoke passed at cycle ..., done_count=...
```

## 6. 编译和运行 SPI smoke test

SPI 用于验证 pad-level simulator 访问路径，不作为后续主流测试路径。

### 6.1 Verilator 生成

```sh
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTop \
  -f verification/verilator/filelists/topchip_top.f \
  --exe software_stack/tests/cpp/test_sim_backend_spi.cpp \
  --Mdir build/verilator/software_stack/sim_backend_spi_smoke \
  --output-groups 0 \
  -CFLAGS "-I$PWD/software_stack/include -I$PWD/verification/verilator/cpp/common"
```

### 6.2 Make 编译

```sh
make -C build/verilator/software_stack/sim_backend_spi_smoke \
  -f VTopChipTop.mk -j 8 OBJCACHE=
```

### 6.3 运行

```sh
./build/verilator/software_stack/sim_backend_spi_smoke/VTopChipTop
```

预期输出类似：

```text
SimBackend SPI smoke passed at cycle ..., done_count=...
```

SPI 运行会明显慢于 D2D。

## 7. 编译和运行 Device mixed 回归

`verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_mixed.cpp` 和 `tb_topchip_spi_mixed.cpp` 的 mixed case 已迁移到 Device 访问层：

```text
software_stack/tests/cpp/test_device_mixed_common.hpp
software_stack/tests/cpp/test_device_mixed_d2d.cpp
software_stack/tests/cpp/test_device_mixed_spi.cpp
```

迁移后的测试不继承 `topchip::TestBase`，只通过 `dexmpc::runtime::Device` 调用：

```text
write_memory
read_memory
send_instruction
wait_next_done
wait_done_count
read_status
```

覆盖算子类型和原 full-chip mixed 一致：

```text
abs
layout_transpose
layout_assemble
reduce_add
reduce_cmp
gemm
mul
add
```

默认 case 集合是完整 34-case mixed 回归。SPI pad-level simulator 很慢，可以通过 `DEXMPC_DEVICE_MIXED_CASE_LIMIT=8` 跑代表性 smoke；8-case smoke 覆盖上述所有算子类型。

### 7.1 D2D full mixed

生成：

```sh
env CCACHE_DISABLE=1 /home/ljj/dex_cycle_model/tools/verilator/bin/verilator \
  -sv --cc --top-module TopChipTopD2dHarness \
  -f verification/verilator/filelists/topchip_top_d2d_harness.f \
  --exe software_stack/tests/cpp/test_device_mixed_d2d.cpp \
  --Mdir build/verilator/software_stack/device_mixed_d2d \
  --output-groups 0 \
  -CFLAGS "-I$PWD/software_stack/include -I$PWD/software_stack/tests/cpp -I$PWD/verification/verilator/cpp/common"
```

编译：

```sh
make -C build/verilator/software_stack/device_mixed_d2d \
  -f VTopChipTopD2dHarness.mk -j 8 OBJCACHE=
```

运行：

```sh
./build/verilator/software_stack/device_mixed_d2d/VTopChipTopD2dHarness
```

分析输出 CSV：

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/software_stack/device_mixed/d2d \
  --out-dir verification/results/software_stack/device_mixed/d2d
```

### 7.2 SPI mixed smoke

SPI 全量 34-case 可以编译运行，但 pad-level SPI 访问明显慢于 D2D。日常建议先跑 8-case smoke：

```sh
env CCACHE_DISABLE=1 /home/ljj/dex_cycle_model/tools/verilator/bin/verilator \
  -sv --cc --top-module TopChipTop \
  -f verification/verilator/filelists/topchip_top.f \
  --exe software_stack/tests/cpp/test_device_mixed_spi.cpp \
  --Mdir build/verilator/software_stack/device_mixed_spi_smoke \
  --output-groups 0 \
  -CFLAGS "-DDEXMPC_DEVICE_MIXED_CASE_LIMIT=8 -I$PWD/software_stack/include -I$PWD/software_stack/tests/cpp -I$PWD/verification/verilator/cpp/common"
```

编译：

```sh
make -C build/verilator/software_stack/device_mixed_spi_smoke \
  -f VTopChipTop.mk -j 1 OBJCACHE=
```

运行：

```sh
./build/verilator/software_stack/device_mixed_spi_smoke/VTopChipTop
```

分析输出 CSV：

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/software_stack/device_mixed/spi \
  --out-dir verification/results/software_stack/device_mixed/spi
```

## 8. 当前验证状态

2026-06-02 restored workspace validation:

- D2D `SimBackend` smoke 已通过，验证了 `Device::open_sim()` 默认 D2D、寄存器读写、Global/Local0/Temp0 SRAM 读写和 `read_status()`。
- Common-only 编译已通过；未启用 `DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND` 时，`SimModel` 会走预期的 runtime error 路径。
- SPI `SimBackend` smoke 已通过。此前失败来自 stale generated model：`build/verilator/topchiptop_legacy_spi_tb_split/VTopChipTop` 是较早生成的产物，当时 `verification/verilator/filelists/topchip.f` 尚未包含 `rtl/sim_models/SramWrapperSP.sv`。当前 filelist 和 `build/verilator/full_chip/topchiptop_legacy_spi_tb/VTopChipTop` 均可正确通过 SPI SRAM readback。
- Device mixed D2D 34-case full 回归已通过，并通过 `analyze_tb_core_top_mixed.py` 做数值校验：`overall: cases=34, pass=34, fail=0, exact=641/641, max_abs_err=0`。
- Device mixed SPI 8-case smoke 已通过，并通过 `analyze_tb_core_top_mixed.py` 做数值校验：`overall: cases=8, pass=8, fail=0, exact=335/335, max_abs_err=0`。
- Device mixed SPI 34-case full 回归可启动并连续完成 reduce 命令，但 pad-level SPI simulator 很慢，本次 900 秒外层超时前未跑完全量；没有观察到功能性 mismatch。
- 本次修复了 `SimBackend::wait_next_done()` 的 doneCount 基准问题。旧逻辑在调用 `wait_next_done()` 时重新读取当前 `doneCount`，短 reduce 指令可能已经完成，导致目标从 1 错设为 2，并报 `timeout waiting for doneCount target=2 got=1`。当前逻辑在 `send_instruction()` 下发命令前记录 observed doneCount，再等待该值之后的下一次完成。

本次 D2D 输出：

```text
SimBackend D2D smoke passed at cycle 1633, done_count=0
```

本次 SPI 输出：

```text
SPI config register smoke passed, cases=44
SPI SRAM smoke passed, cases=15 (representative memory-id sweep)
TopChipTop legacy SPI C++ test passed at core cycle 135676
SimBackend SPI smoke passed at cycle 17788, done_count=0
```

本次 Device mixed D2D 输出：

```text
Device mixed D2D test passed at cycle 59480, cases=34, done_count=34
overall: cases=34, pass=34, fail=0, exact=641/641, max_abs_err=0
```

本次 Device mixed SPI smoke 输出：

```text
Device mixed SPI test passed at cycle 538084, cases=8, done_count=8
overall: cases=8, pass=8, fail=0, exact=335/335, max_abs_err=0
```

更详细的验证记录见：

```text
logs/device_access_validation.md
```

## 9. 上层如何使用

后续上层软件不应直接 include `topchip_sim.hpp`。

推荐 include：

```cpp
#include "dexmpc/runtime/device.hpp"
```

上层只保存：

```cpp
dexmpc::runtime::Device device;
```

后续 `InstructionBuilder`、`OperatorRuntime`、Python binding 都应该基于 `Device` 实现，而不是直接基于 `topchip_sim` 实现。

## 10. 与未来物理芯片 backend 的关系

当前 `FpgaChipBackend` 只是预留接口。

未来真实芯片接入时，应实现同样的接口：

```text
reset
write_register
read_register
write_memory
read_memory
send_instruction
wait_done_count
wait_next_done
read_status
```

这样上层仍然使用：

```cpp
Device
```

而不是直接依赖 simulator 或 FPGA 细节。

未来切换方式应类似：

```cpp
dexmpc::runtime::DeviceOptions options;
options.backend = dexmpc::runtime::BackendKind::FpgaChip;
options.transport = dexmpc::runtime::Transport::D2D;

auto device = dexmpc::runtime::Device::open(options, argc, argv);
```

## 11. 当前实现边界

当前设备访问层已经覆盖：

- simulator backend。
- D2D/SPI transport 选择。
- D2D 默认选项。
- register access。
- SRAM access。
- command send。
- done/status polling。
- 未来 FPGA/物理芯片 backend 接口预留。

当前尚未覆盖：

- GEMM/LUT/transpose 等算子级 API。
- 96-bit 指令自动生成。
- Python binding。
- FPGA/物理芯片真实通信实现。

这些属于后续层：

```text
InstructionBuilder
OperatorRuntime
PythonBinding
FpgaChipBackend implementation
```
