# TopChip Cycle-Accurate Simulator 使用说明

本文档说明当前 TopChip cycle-accurate simulator 的组成、生成方式、C++ 访问接口和推荐使用流程，供后续 Dex_SIM driver、上层指令封装和 compiler runtime 开发参考。

## 1. Simulator 的组成

当前 TopChip cycle-accurate simulator 由两层组成：

1. Verilator 从 SystemVerilog RTL 生成的 C++ 硬件模型。
2. 手写的 C++ driver 封装层，用于简化外部寄存器、SRAM 和指令访问。

核心封装文件是：

```text
verification/verilator/cpp/common/topchip_sim.hpp
```

后续上层软件一般不建议直接操作 Verilator 生成的 `VTopChipTop` 或 `VTopChipTopD2dHarness` 类，而是通过 `topchip_sim.hpp` 中的 `dexsim::topchip::Sim` 和 `dexsim::topchip::TestBase` 访问 TopChip。

## 2. 两种 TopChip 仿真模式

### 2.1 D2D 模式

D2D 模式通过 `TopChipTopD2dHarness` 连接 TopChip 的 D2D 外部访问路径。

该模式推荐用于：

- Dex_SIM driver 开发。
- 指令级软件栈开发。
- compiler runtime 的快速功能验证。
- 大多数 full-chip 功能回归。

对应 Verilator top module：

```text
TopChipTopD2dHarness
```

对应 filelist：

```text
verification/verilator/filelists/topchip_top_d2d_harness.f
```

生成的 C++ 模型类：

```cpp
VTopChipTopD2dHarness
```

### 2.2 SPI 模式

SPI 模式直接使用 pad-level `TopChipTop`，通过 SPI pad 逐 bit 访问芯片内部寄存器和 SRAM。

该模式推荐用于：

- 验证真实芯片 pad-level SPI 访问路径。
- 与 tapeout 后外部通信行为保持一致的慢速回归。

对应 Verilator top module：

```text
TopChipTop
```

对应 filelist：

```text
verification/verilator/filelists/topchip_top.f
```

生成的 C++ 模型类：

```cpp
VTopChipTop
```

SPI 模式会明显慢于 D2D 模式，因为每次访问都模拟完整 SPI bit-level 传输。

## 3. C++ 中如何使用

### 3.1 D2D 模式 include 方式

```cpp
#define DEX_TOPCHIP_TRANSPORT_D2D
#include "verification/verilator/cpp/common/topchip_sim.hpp"
```

### 3.2 SPI 模式 include 方式

```cpp
#define DEX_TOPCHIP_TRANSPORT_SPI
#include "verification/verilator/cpp/common/topchip_sim.hpp"
```

如果希望复用已有 core testbench 逻辑，还需要定义：

```cpp
#define DEXMPC_USE_TOPCHIP_SIM
```

例如已有 wrapper：

```text
verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_mixed.cpp
verification/verilator/cpp/tests/full_chip/tb_topchip_spi_mixed.cpp
```

## 4. TopChip_sim 主要接口

### 4.1 创建和复位

```cpp
dexsim::topchip::Sim sim(argc, argv);
sim.reset();
```

`sim.reset()` 会驱动 TopChip reset，并在 reset 释放后刷新内部状态寄存器 cache。

### 4.2 寄存器访问

```cpp
sim.write_reg(reg_idx, value);
uint32_t value = sim.read_reg(reg_idx);
```

这里的 `reg_idx` 是 DexMPC config register index，不是 byte address。

地址换算规则为：

```text
cfg_addr = BASE + (reg_idx << 3)
```

当前 `BASE = 0x00000000`。

### 4.3 SRAM 访问

单个 128-bit SRAM word：

```cpp
dexsim::Word128 word = {lo32, mid32_0, mid32_1, hi32};

sim.write_mem_word(mem_id, word_addr, word);
auto read_back = sim.read_mem_word(mem_id, word_addr);
```

连续多个 128-bit SRAM word：

```cpp
std::vector<dexsim::Word128> words = ...;

sim.write_mem_words(mem_id, base_word_addr, words);
auto out = sim.read_mem_words(mem_id, base_word_addr, word_count);
```

SRAM 地址换算规则为：

```text
sram_addr = BASE + ((0x8000 + (mpc_mem_id << 11) + word_addr) << 3)
```

core memory ID 到 full-chip MPC memory ID 的映射为：

| Core memory | Core ID | MPC memory ID |
| --- | ---: | ---: |
| Global | 0 | 0 |
| Local0 | 1 | 1 |
| Temp0 | 2 | 5 |
| LUT banks | 9..14 | 9..14 |

D2D SRAM 访问与原始 SV testbench 一致：一个 128-bit SRAM word 被拆成两个独立的 64-bit half-word transaction：

- low 64-bit write ID: `0x0c`
- high 64-bit write ID: `0x0d`
- low 64-bit read ID: `0x2a`
- high 64-bit read ID: `0x2b`

当前没有默认使用多 beat burst，因为现有 TopChip SRAM D2D 路径与原始 SV testbench 一样按单 beat half-word 方式验证。

### 4.4 指令发送和完成等待

如果使用 `dexsim::topchip::TestBase`，可以直接使用：

```cpp
push_cmd(cmd);
topchip_wait_for_next_done(timeout_cycles);
topchip_wait_for_done_count(target_done_count, timeout_cycles);
```

`cmd` 类型为：

```cpp
dexsim::Cmd96
```

已有 helper：

```cpp
auto cmd = dexsim::make_cmd(
    cmd_id,
    opcode,
    subop,
    group_end,
    addr0,
    addr1,
    addr2,
    dim0,
    dim1,
    dim2
);
```

TopChip 模式下推荐通过 `doneCount` 轮询判断命令完成，而不是只依赖 complete pulse。原因是某些短命令的 complete pulse 可能很窄，软件轮询更稳妥。

## 5. D2D mixed 测试完整流程

### 5.1 Verilator 生成

```sh
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTopD2dHarness \
  -f verification/verilator/filelists/topchip_top_d2d_harness.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_mixed.cpp \
  --Mdir build/verilator/full_chip/topchip_d2d_mixed_tb \
  --output-groups 0
```

### 5.2 Make 编译

```sh
make -C build/verilator/full_chip/topchip_d2d_mixed_tb \
  -f VTopChipTopD2dHarness.mk -j 8 OBJCACHE=
```

### 5.3 运行

```sh
./build/verilator/full_chip/topchip_d2d_mixed_tb/VTopChipTopD2dHarness
```

### 5.4 后处理

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/full_chip/d2d/mixed \
  --out-dir verification/results/full_chip/d2d/mixed
```

当前已验证结果：

```text
D2D mixed: 34/34 cases passed, 641/641 exact elements
```

## 6. SPI mixed 测试完整流程

### 6.1 Verilator 生成

```sh
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTop \
  -f verification/verilator/filelists/topchip_top.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_spi_mixed.cpp \
  --Mdir build/verilator/full_chip/topchip_spi_mixed_tb \
  --output-groups 0
```

### 6.2 Make 编译

```sh
make -C build/verilator/full_chip/topchip_spi_mixed_tb \
  -f VTopChipTop.mk -j 8 OBJCACHE=
```

### 6.3 运行

```sh
./build/verilator/full_chip/topchip_spi_mixed_tb/VTopChipTop
```

### 6.4 后处理

```sh
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py \
  --result-root verification/results/full_chip/spi/mixed \
  --out-dir verification/results/full_chip/spi/mixed
```

当前已验证结果：

```text
SPI mixed: 34/34 cases passed, 641/641 exact elements
```

## 7. 作为 Dex_SIM 开发基础的推荐方式

后续开发 Dex_SIM 层时，建议按以下顺序封装：

1. 基于 `dexsim::topchip::Sim` 封装最底层 register read/write。
2. 封装 SRAM read/write，包括 Global、Local0、Temp0 和 LUT memory。
3. 封装 command register 写入和 `push_cmd()`。
4. 封装 completion polling，包括 `doneCount`、`lastDone`、reduce result register。
5. 在此基础上实现 instruction-level API。
6. 最后在 instruction-level API 上实现 compiler runtime。

推荐优先使用 D2D 模式作为开发主路径，因为它比 SPI 模式快很多，并且仍然经过 full-chip D2D 外设路径访问 TopChip 内部 DexMPC core。

SPI 模式主要用于确认 pad-level SPI 通信路径与最终 tapeout 芯片一致。

## 8. 重要注意事项

- `build/verilator/` 下的文件是生成产物，不需要提交到 Git。
- `verification/results/**/*.csv` 和 `.txt` 是仿真输出和后处理结果，也不需要提交。
- TopChip Verilator 生成和编译耗时较长，建议固定使用 `--output-groups 0` 和 `OBJCACHE=`。
- D2D 模式和 SPI 模式共用同一套 `topchip_sim.hpp` 上层接口，只通过宏切换 transport。
- 上层软件不要依赖 `build/verilator/...` 中的生成文件路径；应通过 Make/Verilator flow 生成模型，再在自己的 testbench 或 driver 中 include `topchip_sim.hpp`。
