# DexMPC 软件栈与 Backend 统一方案 QA 记录

日期：2026-06-02

本文记录关于 DexMPC 上层软件栈、compiler 归属、simulator backend 与未来物理芯片 backend 是否统一的讨论结论，供后续工程设计参考。

## Q1：算法到算子之间的“编译”应该由 Python、人工，还是 C++ 实现？

### 问题背景

当前规划的软件栈中，Python 顶层应用负责 MPC 算法逻辑，底层 C++ runtime 负责调用 TopChip simulator 或未来物理芯片。

现阶段可以人工把一个 MPC 算法拆成一串硬件算子，例如：

```text
GEMM -> transpose -> LUT -> reduce -> GEMM
```

但长期来看，如果更换 MPC 算法、优化器结构、机器人模型或控制问题，每次都人工重新拆算子会很低效。因此需要明确：算法到算子的“编译”到底应该放在 Python、C++，还是靠人工完成。

### 结论

建议采用分阶段方案：

```text
短期：人工编译
中期：Python compiler
长期：Python compiler + C++ runtime，必要时把稳定部分下沉到 C++
```

更具体地说：

- 人工编译只适合早期 bring-up 和第一个 demo。
- 长期不应依赖人工编译。
- 推荐先用 Python 实现算法级 compiler。
- C++ 负责稳定的 runtime、指令封装和设备访问。

### 为什么不建议长期人工编译？

人工编译的问题是：

- 每换一个算法都要重新手工拆算子。
- 容易出错。
- 难以维护。
- 难以做自动优化。
- 不适合长期支持多个 MPC 变体。

人工编译适合做第一版验证，例如：

```python
dev.gemm(A, B, C)
dev.transpose(C, D)
dev.lut_sin(D, E)
```

但它不应该成为长期方案。

### 为什么 compiler 前期建议用 Python？

因为当前顶层 MPC 算法和 Jupyter workflow 都在 Python 侧。

Python 做 compiler front-end 有几个明显优势：

- 和现有 MPC Python 代码最接近。
- 修改算法和调试计算图更方便。
- 适合快速尝试不同 MPC formulation。
- 方便和 NumPy/Jupyter/reference model 对比。
- 对初期开发者更友好。

例如 Python compiler 可以负责：

```text
MPC algorithm
    -> operator graph
    -> operator sequence
    -> runtime calls
```

也就是说，Python 不一定直接生成 96-bit 硬件指令，而是先生成更容易理解的算子序列：

```text
gemm(A, B, C)
transpose(C, D)
lut_sin(D, E)
reduce_add(E)
```

### C++ 应该负责什么？

C++ 不建议承担一开始的高层算法编译逻辑，但应该负责硬件相关、稳定且容易复用的部分：

- 设备 driver。
- SRAM read/write。
- register read/write。
- tensor upload/download。
- operator runtime。
- 96-bit 指令封装。
- command 下发。
- doneCount 等待。
- simulator backend / hardware backend 抽象。

尤其是硬件指令封装应该放在 C++。

也就是说：

```text
Python compiler 负责决定“执行哪些算子”
C++ InstructionBuilder 负责决定“这些算子如何变成硬件指令”
C++ backend 负责决定“这些指令如何送到 simulator 或芯片”
```

### 推荐职责划分

| 模块 | 推荐语言 | 职责 |
| --- | --- | --- |
| MPC 顶层算法 | Python | 描述控制算法、输入输出、reference 计算 |
| 编译器前端 | Python | 把算法拆成算子图或算子序列 |
| 简单调度和内存规划 | 初期 Python | 决定算子顺序、临时 buffer 使用 |
| 算子 runtime | C++ | 执行 GEMM、LUT、transpose 等硬件算子 |
| 指令封装 | C++ | 生成 96-bit command |
| 设备访问 | C++ | 读写 register/SRAM，等待完成 |
| simulator backend | C++ | 调用 `topchip_sim` |
| 真实芯片 backend | C++ 或 Python wrapper 调 FPGA API | 访问 FPGA/PCB/芯片链路 |

### 推荐演进路线

#### 阶段 1：人工编译

先手工写固定 MPC kernel 的算子序列。

目标是验证：

- Python 能调 C++。
- C++ 能调 simulator。
- 数据搬运正确。
- 指令执行正确。

#### 阶段 2：Python program runner

把手写算子序列整理成一个简单 program：

```python
program = [
    Gemm(A, B, C),
    Transpose(C, D),
    LutSin(D, E),
]

runtime.run(program)
```

这一步还不需要复杂 compiler。

#### 阶段 3：Python compiler

再让 Python 从更高层的算法描述生成 program：

```python
C = mpc.gemm(A, B)
D = mpc.transpose(C)
E = mpc.sin(D)
```

compiler 自动生成：

```text
GEMM instruction
TRANSPOSE instruction
LUT_SIN instruction
```

#### 阶段 4：稳定部分下沉到 C++

如果某些 pass 很稳定、性能敏感，后续可以再把它们迁移到 C++。

但不建议一开始就把整个 compiler 写成 C++，因为 MPC 算法本身还可能频繁变化。

## Q2：未来物理芯片通过 FPGA/PCB/Jupyter 访问，这个 backend 能否和当前 SimModel 统一？

### 问题背景

当前 TopChip C++ model 与未来物理芯片在顶层接口上是一致的：

- SPI。
- D2D。

不同点在于：

- 当前 simulator 是 Verilator C++ model。
- 未来物理芯片通过 PCB 连接到 FPGA。
- FPGA 侧已有专用 workflow，并可连接到 Python Jupyter Notebook。

因此需要判断：未来 FPGA/物理芯片 backend 能否与当前 simulator backend 统一。

### 结论

可以统一，而且强烈建议统一。

统一的关键是：不要让上层 Python 或 compiler 直接依赖 `topchip_sim`，而是定义一个通用 backend interface。

推荐结构：

```text
Python MPC / Compiler
        |
Operator Runtime
        |
Device Driver
        |
Backend Interface
    /                 \
SimBackend        FpgaChipBackend
    |                 |
topchip_sim       FPGA/Jupyter/PCB/Chip
```

也就是说：

- simulator 是一个 backend。
- 真实芯片也是一个 backend。
- 上层软件通过同一套 Device/Runtime 接口访问它们。

### 为什么可以统一？

因为 simulator 和真实芯片对上层来说都应该提供相同的基本能力：

```text
reset()
write_reg()
read_reg()
write_sram()
read_sram()
send_command()
wait_done()
```

不管底层是：

```text
Verilator C++ model
```

还是：

```text
Python -> FPGA -> PCB -> physical chip
```

只要能提供这些能力，上层 runtime 就可以共用。

### 应该统一什么？

应该统一的是上层软件看到的接口。

例如：

```python
dev = dex.Device(backend="sim_d2d")
```

未来可以切换成：

```python
dev = dex.Device(backend="fpga_spi")
```

或者：

```python
dev = dex.Device(backend="fpga_d2d")
```

但上层调用仍然是：

```python
dev.gemm(A, B, C)
dev.transpose(C, D)
dev.download(C)
```

### 不应该统一什么？

不需要强行统一底层实现细节。

例如：

| 项目 | Simulator backend | FPGA/Chip backend |
| --- | --- | --- |
| register write | C++ 调 Verilator model | Python 或 C++ 调 FPGA API |
| SRAM write | C++ 写 model 内部接口 | 通过 FPGA 发送 SPI/D2D transaction |
| time advance | C++ tick cycle | 真实硬件自然运行 |
| done 等待 | 轮询 Verilator register | 轮询 FPGA/芯片 status |
| debug | waveform / cycle count | FPGA log / logic analyzer / readback |

这些底层细节可以不同，只要向上暴露的 backend interface 一样即可。

### 需要注意的差异

虽然接口可以统一，但 simulator 和物理芯片有几个重要差异。

#### 1. Cycle 控制方式不同

Simulator 可以精确 tick cycle。

真实芯片不能由软件逐 cycle 控制，只能通过外部接口读状态。

因此 backend interface 不应要求上层手动 tick cycle。

推荐上层只使用：

```text
wait_done()
read_status()
```

而不要依赖：

```text
tick()
```

#### 2. 数据传输速度不同

Simulator 中 D2D/SPI 是仿真的。

真实芯片中数据要经过：

```text
Python/Jupyter -> FPGA -> PCB -> chip
```

延迟和吞吐会不同。

因此上层 runtime 应该尽量支持 batch 操作，减少频繁小事务。

#### 3. 错误处理不同

Simulator 的错误可能是：

- illegal command。
- timeout。
- Verilator model 状态异常。

真实芯片还可能有：

- FPGA 通信失败。
- SPI/D2D transaction 失败。
- board reset 问题。
- 电源/时钟状态问题。

所以 backend 层需要统一错误类型，但底层可以保留 backend-specific debug 信息。

#### 4. Debug 能力不同

Simulator 可以看 waveform 和内部信号。

物理芯片只能通过：

- status register。
- FPGA log。
- logic analyzer。
- readback memory。

因此在 simulator 阶段应尽量建立可靠的 register/status/debug convention，方便未来迁移。

### 推荐 backend interface

建议定义一个最小 backend interface：

```text
class IBackend:
    reset()
    write_reg(reg_id, value)
    read_reg(reg_id)
    write_mem(mem_id, word_addr, words)
    read_mem(mem_id, word_addr, word_count)
    send_command(cmd96)
    wait_done(target_done_count, timeout)
    read_status()
```

当前：

```text
TopChipSimBackend
```

内部调用：

```text
topchip_sim.hpp
```

未来：

```text
TopChipFpgaBackend
```

内部调用：

```text
FPGA Python API / Jupyter workflow / board communication API
```

### FPGA/Jupyter backend 的两种实现方式

#### 方式 A：Python backend

如果 FPGA workflow 已经主要在 Python/Jupyter 中，可以先实现 Python 版 backend。

优点：

- 接入最快。
- 方便在 Jupyter 中调试。
- 不需要一开始写复杂 C++ 硬件驱动。

缺点：

- 性能可能较低。
- 与 C++ runtime 集成时要小心边界。

适合早期 bring-up。

#### 方式 B：C++ backend + Python binding

把 FPGA 通信接口封装成 C++ backend，再通过 pybind11 给 Python 使用。

优点：

- 和 simulator C++ runtime 更统一。
- 性能和结构更好。
- 更接近最终工程化软件。

缺点：

- 初期开发成本更高。

适合后期稳定版本。

### 推荐做法

当前建议：

1. 先把 backend interface 设计清楚。
2. simulator backend 用 C++ 实现，复用 `topchip_sim`。
3. FPGA/真实芯片 backend 初期可以用 Python 实现，快速接入 Jupyter workflow。
4. 等 FPGA 通信协议稳定后，再考虑迁移为 C++ backend。

这样既能快速 bring-up 真实芯片，又不会破坏 simulator 侧的软件栈结构。

## 总体建议

### 关于 compiler

推荐路线：

```text
人工编译 -> Python program runner -> Python compiler -> 必要时部分 C++ 化
```

当前不要一开始就实现复杂 C++ compiler。

Python 更适合作为 MPC algorithm compiler 的前端；C++ 更适合做 runtime、指令封装和设备访问。

### 关于 backend

推荐路线：

```text
统一上层接口，不统一底层实现
```

也就是说，上层统一看到：

```text
Device / OperatorRuntime / Backend Interface
```

底层可以分别是：

```text
TopChip simulator
FPGA + physical chip
```

只要 backend interface 一致，Python MPC 应用和 compiler 就可以基本复用。

## 最终简化架构

推荐最终保持如下结构：

```text
Python MPC Algorithm
        |
Python Compiler / Program Runner
        |
Python Binding
        |
C++ Operator Runtime
        |
C++ Instruction Builder
        |
C++ Device Driver
        |
Backend Interface
    /                 \
SimBackend        FpgaChipBackend
    |                 |
TopChip C++ Model  FPGA -> PCB -> TopChip
```

其中：

- Python compiler 负责算法到算子。
- C++ InstructionBuilder 负责算子到 96-bit 指令。
- Device Driver 负责指令下发和状态管理。
- Backend 负责具体访问 simulator 或真实芯片。
