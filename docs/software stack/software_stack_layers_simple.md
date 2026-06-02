# DexMPC 软件栈分层说明（简化版）

本文档用尽量直白的方式说明：从 TopChip simulator 或未来真实芯片，到最上层 Python MPC 应用之间，工程上应该有哪些 wrapper layer，每一层负责什么，以及硬件指令应该在哪一层封装。

本文档面向当前阶段的开发讨论，不追求一开始实现复杂 compiler、复杂调度器或高级优化。当前目标是先把工程结构搭清楚，让 Python 应用能够稳定调用底层 TopChip simulator。

## 1. 先给出一句话结论

我们需要的不是一开始就做一个很复杂的 compiler，而是先做一个清晰的分层软件栈：

```text
Python MPC 应用
    |
Python 接口层
    |
C++ 算子接口层
    |
C++ 指令封装层
    |
C++ 设备访问层
    |
TopChip simulator 或真实芯片
```

其中：

- Python 应用不应该知道硬件寄存器地址。
- Python 应用不应该自己拼 96-bit 指令。
- 指令封装应该放在 C++ 指令封装层。
- simulator 和未来真实芯片应该尽量共用上层接口，只替换最底层 backend。

## 2. 为什么需要这些 wrapper layer

当前我们已经有 `topchip_sim`，它可以读写寄存器和 SRAM，也可以发送指令。

但是，`topchip_sim` 仍然比较接近硬件，使用它时还需要理解：

- 哪个寄存器是 command word。
- 哪个寄存器是 doneCount。
- SRAM 地址怎么计算。
- 96-bit command 怎么打包。
- opcode、subop、addr、dim 怎么填。

这些内容不应该暴露给最上层 Python MPC 应用。

所以我们需要逐层包装，把底层细节藏起来。越往上，接口越接近算法；越往下，接口越接近硬件。

## 3. 推荐的最小工程分层

### Layer 0：TopChip simulator 或真实芯片

这一层是最底层目标。

当前阶段是：

```text
Verilator 生成的 TopChip C++ model
```

未来真实芯片阶段是：

```text
实际 TopChip 芯片
```

这一层本身不提供高级软件接口，只能通过外部通信方式访问。

当前 simulator 访问方式：

- D2D harness。
- SPI pad-level。

未来真实芯片访问方式可能是：

- SPI driver。
- D2D driver。
- AXI bridge。
- 其他板级通信接口。

### Layer 1：Backend 访问层

这一层负责和“具体设备”打交道。

如果目标是 simulator，它调用：

```text
topchip_sim
```

如果目标是真实芯片，它调用：

```text
Linux driver / SPI driver / PCIe driver / board support package
```

这一层应该提供统一接口，例如：

```text
reset()
write_reg(reg_id, value)
read_reg(reg_id)
write_sram(mem_id, addr, data)
read_sram(mem_id, addr)
wait_done()
```

这一层只负责“怎么访问设备”，不负责理解 MPC 算法。

工程意义：

- simulator backend 和真实芯片 backend 可以互换。
- 上层代码不用关心底层是 Verilator simulator 还是真实芯片。

当前阶段可以先只有一个 backend：

```text
TopChipSimBackend
```

它内部调用 `topchip_sim.hpp`。

未来再增加：

```text
TopChipHardwareBackend
```

它内部调用真实芯片驱动。

### Layer 2：设备 Driver 层

这一层是对 backend 的进一步整理，面向 DexMPC accelerator。

它不直接暴露很底层的 D2D/SPI 细节，而是提供一个“设备对象”。

可以理解为：

```text
Device = 一个可以执行 DexMPC 指令的设备
```

典型接口：

```text
device.reset()
device.upload_data(...)
device.download_data(...)
device.send_instruction(...)
device.wait_instruction_done(...)
```

这一层负责：

- 初始化设备。
- 复位设备。
- 管理运行状态。
- 调用 backend 读写寄存器和 SRAM。
- 调用 backend 发送底层 command。
- 统一错误处理。

这一层仍然不应该包含复杂 MPC 算法。

### Layer 3：指令封装层

这一层非常关键。

硬件真正执行的是 96-bit command。但是上层软件不应该手动拼 bit。

所以需要一个专门的指令封装层，负责把“人能看懂的参数”变成“硬件能执行的 command”。

例如上层想表达：

```text
执行 GEMM:
C = A x B
A 在 global SRAM 地址 0
B 在 global SRAM 地址 32
C 写到 local SRAM 地址 0
矩阵维度 M, N, K
```

指令封装层负责把它变成：

```text
opcode
subop
src0 address
src1 address
dst address
dim0
dim1
dim2
group_end
cmd_id
```

然后进一步打包成硬件需要的 96-bit command。

因此，回答一个关键问题：

## 4. 哪一层负责指令封装？

**指令封装应该由 C++ 指令封装层负责。**

也就是这一层：

```text
Instruction Builder / Command Builder
```

它的位置应该在：

```text
C++ 算子接口层
    |
C++ 指令封装层   <-- 在这里封装硬件指令
    |
C++ 设备访问层
```

不建议在 Python 层封装指令，原因是：

- Python 层更适合表达算法，不适合处理硬件 bit field。
- 指令格式变化时，不希望大量 Python 应用代码都要修改。
- C++ 层更接近 simulator 和未来真实芯片 driver。
- C++ 层更容易和现有 `topchip_sim` 复用。

不建议在最底层 backend 中封装指令，原因是：

- backend 应该只负责寄存器/SRAM/通信访问。
- 指令格式属于 DexMPC accelerator 的逻辑，不属于 D2D/SPI 通信本身。

所以较合理的职责划分是：

| 层级 | 是否理解指令格式 |
| --- | --- |
| Python MPC 应用 | 不理解 |
| Python 接口层 | 尽量不理解 |
| C++ 算子接口层 | 知道要执行什么算子 |
| C++ 指令封装层 | 负责生成 96-bit 指令 |
| C++ 设备访问层 | 负责把指令写进硬件寄存器 |
| Backend 层 | 负责实际寄存器/SRAM 访问 |

### Layer 4：算子接口层

这一层把硬件指令进一步包装成“算子”。

对上层来说，不应该写：

```text
make_cmd(opcode=3, subop=0, addr0=..., addr1=..., addr2=...)
```

而应该写：

```text
gemm(A, B, C)
transpose(A, B)
lut_sin(A, B)
reduce_add(A)
```

这一层负责：

- 检查输入输出矩阵维度。
- 确认数据已经放在 SRAM 中。
- 调用指令封装层生成 command。
- 调用设备 Driver 层发送 command。
- 等待计算完成。
- 必要时把结果读回来。

举例：

```text
gemm(A, B, C)
```

内部实际做的事情是：

1. 检查 A、B、C 的 shape。
2. 找到 A、B、C 在 SRAM 中的地址。
3. 调用 Instruction Builder 生成 GEMM command。
4. 调用 Device Driver 发送 command。
5. 等待 doneCount 更新。
6. 返回执行结果。

### Layer 5：Python Binding 层

这一层负责把 C++ 接口暴露给 Python。

推荐使用：

```text
pybind11
```

Python 层看到的接口应该比较简单，例如：

```python
import dexmpc_sim as dex

dev = dex.Device("sim_d2d")

A = dev.upload(array_a)
B = dev.upload(array_b)
C = dev.empty((16, 16))

dev.gemm(A, B, C)

result = dev.download(C)
```

Python Binding 层负责：

- 创建 C++ device 对象。
- 把 NumPy array 传给 C++。
- 把 C++ 结果返回给 Python。
- 暴露 `gemm()`、`transpose()`、`lut_sin()` 等算子接口。

这一层不应该直接操作寄存器，也不应该直接拼 96-bit 指令。

### Layer 6：Python MPC 应用层

这是最高层。

这一层只关心 MPC 算法本身，例如：

- 当前机器人状态。
- 目标轨迹。
- 代价函数。
- 约束。
- solver 迭代流程。

Python MPC 应用应该调用比较高级的接口：

```python
u = solver.step(x_current, x_target)
```

或者在早期阶段，先显式调用算子：

```python
tmp = dev.gemm(A, B)
tmp2 = dev.lut_sin(tmp)
out = dev.transpose(tmp2)
```

这层不应该关心：

- `cmdWord_0_0` 是哪个寄存器。
- doneCount 在哪个地址。
- SRAM word 地址怎么计算。
- GEMM 的 opcode 是多少。

## 5. 当前阶段不需要做复杂 compiler

之前提到 compiler、IR、scheduler、fusion 等内容，是长期目标。

但从当前工程阶段看，可以先不实现复杂 compiler。

建议分三步走：

### 第一步：手写算子调用

先让 Python 能直接调用硬件算子：

```python
dev.gemm(A, B, C)
dev.lut_sin(C, D)
dev.transpose(D, E)
```

这一阶段不需要 compiler。

目标是验证：

- Python 能调用 C++。
- C++ 能调用 TopChip simulator。
- 数据能写入 SRAM。
- 指令能正确发送。
- 结果能正确读回。

### 第二步：手写 operator sequence

把一个 MPC kernel 拆成固定算子序列：

```python
program = [
    gemm(A, B, C),
    transpose(C, D),
    lut_sin(D, E),
    gemm(E, F, G),
]
```

然后 runtime 按顺序执行。

这一阶段可以叫：

```text
Program Runner
```

它还不是复杂 compiler，只是一个顺序执行器。

### 第三步：再做简单 compiler

等前两步稳定后，再考虑让 Python 自动构建计算图：

```python
C = mpc.gemm(A, B)
D = mpc.transpose(C)
E = mpc.sin(D)
```

然后 compiler 自动生成 operator sequence。

所以当前不需要一上来就设计复杂 IR。

## 6. 推荐的最小可实现版本

当前最小可实现版本建议只包含以下组件：

```text
TopChipSimBackend
Device
InstructionBuilder
OperatorRuntime
PythonBinding
PythonExample
```

每个组件的职责如下。

### 6.1 TopChipSimBackend

负责调用 `topchip_sim`。

提供：

```text
reset
read_reg
write_reg
read_sram
write_sram
wait_done
```

### 6.2 Device

表示一个 DexMPC 设备。

负责：

- 保存 backend。
- 管理设备状态。
- 提供统一设备接口。

### 6.3 InstructionBuilder

负责封装硬件指令。

提供：

```text
build_gemm(...)
build_lut(...)
build_transpose(...)
build_reduce(...)
build_add(...)
build_mul(...)
```

输出：

```text
96-bit command
```

### 6.4 OperatorRuntime

负责把算子变成指令并执行。

提供：

```text
gemm(...)
lut_sin(...)
lut_cos(...)
softplus(...)
transpose(...)
reduce_add(...)
add(...)
mul(...)
```

内部调用：

```text
InstructionBuilder -> Device -> Backend -> topchip_sim
```

### 6.5 PythonBinding

负责把 C++ 的 Device 和 OperatorRuntime 暴露给 Python。

Python 看到的是：

```python
dev = dex.Device()
dev.gemm(A, B, C)
```

### 6.6 PythonExample

用于验证整个链路。

例如：

```python
import dexmpc_sim as dex

dev = dex.Device("sim_d2d")
dev.reset()

A = dev.upload(a_np)
B = dev.upload(b_np)
C = dev.empty((16, 16))

dev.gemm(A, B, C)
out = dev.download(C)
```

## 7. simulator 和真实芯片如何共用一套上层软件

关键是把最底层做成 backend。

建议接口：

```text
IBackend
  reset()
  write_reg()
  read_reg()
  write_sram()
  read_sram()
  wait_done()
```

当前实现：

```text
TopChipSimBackend : IBackend
```

未来实现：

```text
TopChipHardwareBackend : IBackend
```

上层结构保持不变：

```text
Python
  -> OperatorRuntime
    -> InstructionBuilder
      -> Device
        -> IBackend
```

这样从 simulator 切换到真实芯片时，主要替换：

```text
TopChipSimBackend
```

为：

```text
TopChipHardwareBackend
```

而 Python 应用、算子接口、指令封装都不需要大改。

## 8. 一个具体例子：Python 调用 GEMM 时发生了什么

假设 Python 写：

```python
dev.gemm(A, B, C)
```

内部流程应该是：

```text
Python dev.gemm(A, B, C)
    |
pybind11 调用 C++ OperatorRuntime::gemm(A, B, C)
    |
检查 A/B/C shape 是否合法
    |
查询 A/B/C 在 SRAM 中的位置
    |
InstructionBuilder::build_gemm(...)
    |
生成 96-bit GEMM command
    |
Device::send_instruction(command)
    |
Backend::write_reg(cmdWord0, ...)
Backend::write_reg(cmdWord1, ...)
Backend::write_reg(cmdWord2, ...)
Backend::write_reg(cmdCtrl, 1)
Backend::write_reg(cmdCtrl, 0)
    |
Backend::wait_done()
    |
返回 Python
```

如果 C 的结果需要回到 Python：

```text
Backend::read_sram(...)
    |
C++ 转成 NumPy array
    |
返回 Python
```

## 9. 建议的开发顺序

推荐按下面顺序开发，不要一开始做复杂 compiler：

1. 写 C++ `InstructionBuilder`。
2. 写 C++ `Device`，内部使用 `topchip_sim`。
3. 写 C++ `OperatorRuntime::gemm()`。
4. 用 C++ 测试 GEMM。
5. 加 pybind11。
6. 用 Python 调 GEMM。
7. 继续加 LUT、transpose、reduce、add、mul。
8. 写一个 Python MPC kernel demo，手动调用这些算子。
9. 等手动算子调用稳定后，再做简单 compiler 或 program runner。

## 10. 总结

当前最清晰、最符合工程实践的结构是：

```text
Python MPC Application
    |
Python Binding
    |
Operator Runtime
    |
Instruction Builder
    |
Device Driver
    |
Backend
    |
TopChip simulator / physical chip
```

其中：

- `Backend` 负责访问 simulator 或真实芯片。
- `Device Driver` 负责设备级控制。
- `Instruction Builder` 负责封装 96-bit 硬件指令。
- `Operator Runtime` 负责提供 GEMM、LUT、transpose 等算子 API。
- `Python Binding` 负责把 C++ API 暴露给 Python。
- `Python MPC Application` 只负责算法逻辑。

当前阶段建议先实现这套最小结构，不要急于实现复杂 compiler、operator fusion 或高级 scheduling。等 Python 能稳定调用单算子和固定 MPC operator sequence 后，再逐步引入 compiler。
