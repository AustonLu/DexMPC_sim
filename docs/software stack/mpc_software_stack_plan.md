# DexMPC 上层软件栈与编译器开发规划

本文档面向内部讨论，梳理从 TopChip cycle-accurate simulator 到上层 Python MPC 应用之间仍需开发的组件、工程集成方式和分阶段实施计划。

## 1. 当前基础

当前已经具备的基础能力：

- TopChip RTL 已可通过 Verilator 生成 cycle-accurate C++ model。
- `topchip_sim` 已封装 TopChip 的外部访问路径，支持寄存器读写、SRAM 读写、指令发送和完成状态轮询。
- full-chip D2D/SPI mixed test 已验证 TopChip 外部访问链路和核心算子执行链路可工作。
- Python 侧已有或计划已有顶层 MPC 算法、外部输入处理和机器人控制逻辑。

因此，后续工作的重点不再是 RTL 到 C++ model 的可行性验证，而是构建完整的软件栈：

```text
Python MPC Application
        |
Python API / Runtime Binding
        |
MPC Compiler / Graph Lowering / Scheduler
        |
Instruction Runtime / Dex_SIM Driver
        |
TopChip_sim C++ Driver
        |
Verilated TopChip Cycle-Accurate Model
```

## 2. 总体目标

最终目标是让 Python 层 MPC 算法可以通过统一的软件接口调用硬件加速路径：

1. Python 层描述或调用 MPC 算法。
2. 编译器识别 MPC 中的矩阵、非线性函数、转置、归约等算子。
3. 编译器将算子 lowering 为硬件支持的指令序列。
4. runtime 负责内存分配、数据搬运、指令下发、状态轮询和结果回读。
5. 当前阶段目标后端是 TopChip cycle-accurate simulator。
6. 后续可将同一套上层 runtime 迁移到真实芯片驱动。

## 3. 仍需开发的核心组件

### 3.1 TopChip 低层 Driver 层

目标：在 `topchip_sim` 之上形成更稳定、更面向软件栈的 C++ driver API。

需要开发的能力：

- 设备生命周期管理：
  - 初始化 TopChip simulator。
  - reset。
  - 关闭和资源释放。
- 基础寄存器访问：
  - config register read/write。
  - status register refresh。
  - doneCount、lastDone、engineStatus、allDoneReg 查询。
- SRAM 访问封装：
  - global/local/temp/LUT memory 的 typed read/write。
  - 支持 FP16 matrix/vector 与 `Word128` 之间转换。
  - 支持连续矩阵块读写。
- 指令发送：
  - command word 生成。
  - command FIFO 状态检查。
  - 单条指令发送。
  - 指令 batch 发送。
- 完成等待：
  - doneCount polling。
  - timeout 处理。
  - illegal command、overflow、engine busy 等异常上报。

建议命名：

```text
DexSimDevice
DexSimDriver
```

### 3.2 硬件指令抽象层

目标：把底层 96-bit command 打包细节隐藏起来，对上层暴露结构化 instruction API。

需要支持的 instruction 类型：

- GEMM / GEMV / DOT / OUTER。
- elementwise MUL。
- elementwise ADD。
- LUT nonlinear:
  - sin。
  - cos。
  - softplus。
- ABS。
- Reduce:
  - add reduce。
  - compare reduce。
- Data layout:
  - transpose。
  - assemble。

建议定义统一 IR：

```text
Instruction {
  id
  opcode
  subop
  src0
  src1
  dst
  dims
  flags
}
```

其中 `src0/src1/dst` 不直接使用裸整数地址，而应使用 compiler/runtime 分配出的 logical tensor handle。

### 3.3 Tensor / Memory Runtime

目标：管理 accelerator 可见的 SRAM 空间，解决 Python/编译器张量和硬件 memory address 之间的映射。

需要开发的能力：

- Tensor descriptor：
  - shape。
  - dtype。
  - layout。
  - memory bank。
  - base word address。
  - element count。
  - word count。
- Memory allocator：
  - global/local/temp SRAM 分配。
  - 生命周期管理。
  - 临时 buffer 复用。
  - bank selection 策略。
- Data movement：
  - host to SRAM。
  - SRAM to host。
  - tensor clear。
  - tensor copy。
- Layout 约束：
  - row-major 初版优先。
  - 后续根据硬件算子要求扩展布局描述。

初期可以采用简单静态分配策略；稳定后再实现 lifetime analysis 和 buffer reuse。

### 3.4 算子级 Runtime API

目标：提供面向软件开发的 operator-level API，不需要用户手写 instruction。

建议 API 形态：

```text
gemm(A, B, C, m, n, k)
lut_sin(A, C, rows, cols)
transpose(A, C, rows, cols)
reduce_add(A)
```

每个 operator API 内部完成：

1. 检查 tensor shape 和 dtype。
2. 确定硬件 memory address。
3. 生成 instruction。
4. 发送 instruction。
5. 根据同步策略等待完成或延迟等待。

需要支持两种执行模式：

- synchronous：每个 operator 发送后立即等待完成。
- asynchronous/batched：多个 operator 编排后统一等待。

### 3.5 编译器前端

目标：接收上层 MPC 算法描述，构建可优化的算子图。

可能路线：

1. 手写 Python DSL。
2. 从 NumPy 风格代码手动标注关键计算图。
3. 后续探索接入 MLIR、TVM、JAX trace 或 PyTorch FX。

建议初期采用轻量 Python DSL，降低不确定性。例如：

```python
C = mpc.gemm(A, B)
Y = mpc.sin(C)
Z = mpc.transpose(Y)
```

DSL 只负责记录 graph，不立即执行。随后由 compiler pass lowering 到硬件 instruction sequence。

### 3.6 编译器 IR

建议至少分三层 IR：

#### Graph IR

面向算法表达：

- Tensor。
- Operator。
- Data dependency。
- Shape。
- Dtype。

#### Operator IR

面向硬件算子：

- GEMM。
- LUT。
- Layout。
- Reduce。
- Elementwise。

这一层应已经消除高层复合操作。

#### Instruction IR

面向硬件指令：

- opcode。
- subop。
- packed addresses。
- dims。
- group_end。
- command id。

Instruction IR 最终可直接打包成 96-bit command。

### 3.7 Compiler Passes

需要逐步实现的 pass：

- shape inference。
- dtype checking。
- memory planning。
- operator lowering。
- operator fusion。
- scheduling。
- instruction id assignment。
- group boundary insertion。
- command packing。

初期最重要的是：

1. shape inference。
2. memory planning。
3. lowering。
4. command packing。

fusion 和复杂 scheduling 可以放到后续阶段。

### 3.8 Operator Fusion

目标：减少中间 SRAM 写回和指令调度开销。

候选 fusion：

- GEMM + elementwise ADD。
- GEMM + LUT nonlinear。
- transpose + GEMM 的 layout-aware 优化。
- 多个 elementwise 算子融合。

需要注意：fusion 必须以硬件实际支持的数据路径为边界。如果硬件没有对应 fused operator，compiler 只能做 memory reuse 或 scheduling 层面的优化，而不能假设硬件可在单指令内完成。

### 3.9 Operator Scheduling

目标：根据硬件资源和数据依赖优化执行顺序。

初期策略：

- 按拓扑序执行。
- 每条指令完成后再发下一条，便于 debug。

中期策略：

- 在 command FIFO 可容纳范围内批量发送。
- reduce 类指令因结果寄存器读取时序特殊，可单独调度。
- 尽量复用 temp buffer。

后期策略：

- 基于算子 latency model 做 list scheduling。
- 基于 SRAM bank conflict 规避。
- 基于数据生命周期做 buffer reuse。

### 3.10 Python Binding

目标：让 Python 顶层应用可以调用 C++ runtime。

推荐方案：

- 使用 `pybind11` 暴露 C++ driver/runtime。
- Python 层只持有 device handle 和 tensor handle。
- 大规模数据通过 NumPy array 与 C++ buffer 转换。

建议模块名：

```text
dexmpc_sim
```

示例接口：

```python
import dexmpc_sim as dex

dev = dex.Device(transport="d2d")
A = dev.upload(np_array_A)
B = dev.upload(np_array_B)
C = dev.empty(shape=(m, n), dtype="fp16")
dev.gemm(A, B, C)
out = dev.download(C)
```

后续 compiler 接口：

```python
graph = dex.compile(mpc_model)
result = graph.run(inputs)
```

### 3.11 Python MPC Application Integration

目标：将机器人 MPC 顶层算法接入 compiler/runtime。

需要明确：

- MPC 输入：
  - 当前状态。
  - 目标轨迹。
  - 约束参数。
  - 动力学参数。
- MPC 输出：
  - 控制量。
  - 优化状态。
  - solver status。
- 需要加速的计算热点：
  - dynamics linearization。
  - cost/gradient/Hessian 相关矩阵计算。
  - rollout。
  - constraint projection。
  - nonlinear function lookup。

建议先选一个固定 MPC kernel 作为端到端 demo，而不是一开始支持所有 MPC 变体。

## 4. 工程目录建议

建议在现有仓库中逐步形成如下结构：

```text
include/
  dexmpc/
    sim/
    runtime/
    compiler/

src/
  sim/
  runtime/
  compiler/
  bindings/

python/
  dexmpc_sim/
    __init__.py
    graph.py
    tensor.py
    compiler.py
    runtime.py

tests/
  cpp/
  python/
  integration/

examples/
  mpc_demo/

docs/
  cpp model/
    topchip_cycle_sim_usage.md
  software stack/
    mpc_software_stack_plan.md
logs/
  software_stack_backend_qa_log.md
```

初期可以先放在 `verification/verilator/cpp` 附近快速实验，但一旦开始形成上层软件栈，建议迁移到独立 `src/`、`include/`、`python/` 结构，避免 verification 目录承载过多 runtime 代码。

## 5. 分阶段开发计划

### Phase 0：接口冻结和最小设计文档

目标：明确当前 simulator 作为底座的边界。

任务：

- 梳理 `topchip_sim` 对外接口。
- 明确 D2D/SPI 两种 transport 的使用场景。
- 固化寄存器和 SRAM address map。
- 固化 instruction encoding 文档。
- 明确当前支持的硬件 operator 列表和限制。

交付物：

- simulator 使用文档。
- instruction encoding 文档。
- operator capability 文档。

### Phase 1：C++ Dex_SIM Driver

目标：在 `topchip_sim` 之上实现稳定的 C++ driver/runtime 最小闭环。

任务：

- 实现 device abstraction。
- 实现 register/SRAM typed API。
- 实现 tensor descriptor。
- 实现基础 memory allocator。
- 实现 command builder。
- 实现同步 operator API：
  - GEMM。
  - LUT。
  - transpose。
  - reduce。
  - add/mul。
- 建立 C++ unit tests。

交付物：

- C++ `DexSimDevice`。
- C++ operator runtime。
- C++ 单算子测试。
- C++ mixed operator 测试。

### Phase 2：Python Binding

目标：让 Python 能直接调用 C++ runtime。

任务：

- 引入 `pybind11`。
- 暴露 Device、Tensor、Operator API。
- 支持 NumPy FP16 upload/download。
- 支持 Python 侧同步执行单算子。
- 建立 Python unit tests。

交付物：

- Python package `dexmpc_sim`。
- Python 单算子 demo。
- Python/C++ 数据一致性测试。

### Phase 3：轻量 Compiler IR

目标：从手写 operator sequence 升级到 graph-based 编译。

任务：

- 定义 Python Graph IR。
- 定义 Tensor/Op 节点。
- 实现 shape inference。
- 实现 graph validation。
- 实现 lowering 到 Operator IR。
- 实现 lowering 到 Instruction IR。
- 实现 command sequence generation。

交付物：

- Python DSL。
- graph compiler。
- graph-to-instruction 测试。

### Phase 4：Memory Planning 和 Scheduling

目标：让 compiler 自动管理 SRAM 和执行顺序。

任务：

- 实现 tensor lifetime analysis。
- 实现 global/local/temp allocator。
- 实现临时 buffer reuse。
- 实现拓扑调度。
- 支持 batch command issue。
- 对 reduce 指令做特殊调度处理。

交付物：

- memory planner。
- scheduler。
- end-to-end graph execution。

### Phase 5：MPC Kernel 端到端 Demo

目标：选择一个代表性 MPC kernel，跑通 Python 到 TopChip simulator 的全流程。

任务：

- 选择固定维度 MPC kernel。
- 将关键计算表达为 compiler graph。
- 编译为 instruction sequence。
- 在 TopChip simulator 上执行。
- 与 Python reference 对比数值结果。
- 记录 cycle count 和性能瓶颈。

交付物：

- Python MPC demo。
- end-to-end correctness report。
- cycle-level profiling report。

### Phase 6：优化与真实芯片迁移准备

目标：提高性能并为真实芯片驱动留出接口。

任务：

- operator fusion。
- scheduling 优化。
- memory bank conflict 优化。
- command batching 优化。
- latency model。
- 将 simulator transport 抽象为 backend interface。
- 预留 real hardware backend。

交付物：

- optimized compiler passes。
- simulator backend。
- hardware backend interface。
- regression benchmark suite。

## 6. 推荐的优先级

短期优先级：

1. C++ Dex_SIM driver。
2. Tensor/memory abstraction。
3. operator-level C++ API。
4. Python binding。
5. Python 单算子和 mixed operator 测试。

中期优先级：

1. Python DSL。
2. compiler IR。
3. memory planning。
4. instruction scheduling。
5. MPC kernel demo。

长期优先级：

1. operator fusion。
2. latency-aware scheduling。
3. real hardware backend。
4. full MPC application integration。

## 7. 主要风险和应对

### 7.1 Python 算法难以自动解析

风险：直接从任意 Python/NumPy MPC 代码自动提取计算图难度较高。

建议：初期使用显式 DSL 或手写 graph builder，不追求自动捕获任意 Python 代码。

### 7.2 SRAM 管理复杂

风险：MPC 中间 tensor 多，SRAM 容量有限。

建议：先静态分配，后续加入 lifetime analysis 和 buffer reuse。

### 7.3 Reduce 指令完成和结果读取特殊

风险：reduce result 通过状态寄存器返回，调度上不同于普通写 SRAM 的算子。

建议：compiler scheduler 中将 reduce 作为带 side-effect 的特殊 op，必要时单独等待完成。

### 7.4 D2D 和 SPI 性能差异大

风险：SPI simulator 很慢，不适合频繁软件开发回归。

建议：D2D 作为主开发 backend，SPI 作为 pad-level smoke/regression backend。

### 7.5 Simulator backend 与真实芯片 backend 分裂

风险：如果上层 runtime 直接依赖 simulator 细节，后续迁移真实芯片困难。

建议：尽早定义 backend interface，将 simulator backend 和 future hardware backend 分离。

## 8. 建议的近期任务清单

近期可以按以下顺序推进：

1. 定义 C++ `Device` / `Tensor` / `Instruction` 基础类。
2. 将 `topchip_sim` 包装为 `TopChipSimulatorBackend`。
3. 实现 FP16 matrix upload/download。
4. 实现 GEMM operator API 并与 C++ reference 对比。
5. 实现 LUT、transpose、reduce、add、mul operator API。
6. 引入 pybind11，暴露 Device/Tensor/operator API。
7. 用 Python 调用 GEMM/LUT/mixed operators。
8. 定义最小 Python graph DSL。
9. 实现 graph lowering 到 instruction list。
10. 选择一个固定 MPC kernel 做端到端 demo。

## 9. 结论

当前 TopChip cycle-accurate simulator 已经具备作为上层软件栈底座的条件。下一步工程重点应从 RTL 验证转向软件抽象层建设：先完成 C++ Dex_SIM driver 和 tensor/operator runtime，再通过 pybind11 接入 Python，最后构建轻量 compiler IR、memory planner 和 scheduler。

建议以 D2D simulator backend 作为主要开发路径，保持 SPI backend 作为 pad-level 验证路径。这样可以在保证 full-chip 行为一致性的同时，获得足够快的开发迭代速度。
