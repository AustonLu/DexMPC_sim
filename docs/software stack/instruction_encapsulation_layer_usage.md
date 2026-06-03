# DexMPC 指令封装层接口说明

本文档说明当前 C++ 指令封装层的接口、使用方式和设计方法。该层对应
`docs/software stack/software_stack_layers_simple.md` 中的 Layer 3，位于 C++
设备访问层之上，负责把上层可读的计算请求封装成硬件可执行的 96-bit command，
并提供可展开为 config register 写入序列的接口。

当前实现文件：

```text
software_stack/include/dexmpc/runtime/instruction.hpp
```

当前测试文件：

```text
software_stack/tests/cpp/test_instruction_layer.cpp
software_stack/tests/cpp/test_instruction_runtime_d2d.cpp
software_stack/tests/cpp/test_instruction_runtime_spi.cpp
software_stack/tests/cpp/test_instruction_mixed_common.hpp
software_stack/tests/cpp/test_instruction_mixed_d2d.cpp
software_stack/tests/cpp/test_instruction_mixed_spi.cpp
```

测试分层约定：

- 原始 backend/device 层 tb 保留原文件名，不在 instruction layer 迁移中覆盖：
  `test_sim_backend_*`、`test_device_mixed_*`。
- instruction encapsulation layer 使用独立 tb：
  `test_instruction_layer.cpp`、`test_instruction_runtime_*`、`test_instruction_mixed_*`。
- mixed 测试结果也分目录保存，device 层使用 `device_mixed`，instruction 层使用
  `instruction_mixed`。

## 1. 核心对象

### 1.1 VariableRef

`VariableRef` 描述一个高层变量在硬件 SRAM 中的位置和形状：

```cpp
struct VariableRef {
    std::string name;
    int mem_id;
    int word_addr;
    int elem_count;
    int word_count;
    int rows;
    int cols;
};
```

其中：

- `name` 是上层访问变量时使用的稳定名称。
- `mem_id` 使用 core command 视角的 SRAM ID，例如 `dexsim::kMemGlobal`、
  `dexsim::kMemLocal0`、`dexsim::kMemTemp0`。
- `word_addr` 是 128-bit SRAM word 地址。
- `elem_count` 是 FP16 element 数量。
- `word_count = ceil(elem_count / 8)`。
- `rows`、`cols` 用于矩阵类指令的维度检查。

`VariableRef::packed_addr()` 会生成 command 字段使用的 packed address。

### 1.2 VariableAllocator

`VariableAllocator` 管理变量地址空间。它维护每个 SRAM memory 独立的分配游标：

```cpp
VariableAllocator allocator;
auto a = allocator.allocate_matrix("A", dexsim::kMemGlobal, 16, 16);
auto b = allocator.allocate_matrix("B", dexsim::kMemLocal0, 16, 16);
auto tmp = allocator.allocate_vector("tmp", dexsim::kMemTemp0, 32);
```

当前策略：

- 每个 `mem_id` 单独维护 high-water allocation cursor 和 free-list。
- 每次分配按 `ceil(elem_count / 8)` 计算 128-bit word 数。
- 优先从对应 `mem_id` 的 free-list first-fit 复用已释放区间。
- free-list 无可用区间时，从 high-water cursor 分配新地址。
- high-water 新分配变量之间保留 1 个 128-bit word 的 guard gap，便于调试地址重叠；free-list 复用时按释放区间紧凑复用。
- 分配前检查 SRAM depth，超过硬件 SRAM 范围会抛出异常。
- 分配前检查与已有变量是否重叠，重叠会抛出异常。
- 变量名必须唯一，重复名称会抛出异常。

如果上层已经决定了某个变量的物理地址，可以绑定已有区域：

```cpp
allocator.bind_existing("input", dexsim::kMemGlobal, 64, 256, 16, 16);
allocator.bind_existing_words("scratch", dexsim::kMemTemp0, 128, 8);
```

`bind_existing()` 用于带 element 数量和矩阵形状的变量。
`bind_existing_words()` 用于按 128-bit word 直接绑定一段 SRAM 区间。
绑定成功后，allocator 会推进对应 SRAM 的分配游标，避免后续自动分配覆盖已绑定区域。
如果绑定区域与 free-list 中的已释放区间重叠，allocator 会从 free-list 中扣除对应区间，
避免后续自动分配再次复用同一地址。

变量用完后应显式释放：

```cpp
allocator.release("tmp");
```

释放行为：

- 变量会从 live variable table 中移除。
- 被释放的 `[word_addr, word_addr + word_count)` 区间会进入对应 `mem_id` 的 free-list。
- 相邻或重叠的 free-list 区间会自动合并。
- 释放后的变量名可重新分配。
- 重复释放或释放未知变量会抛出异常。

注意：`VariableRef` 是一个普通值对象。如果上层在释放变量后仍保存旧的 `VariableRef`，
C++ 类型系统不会自动阻止使用这个旧对象。推荐上层通过 `InstructionRuntime` 的变量名接口
构造指令，这样释放后的变量名查找会立即失败，避免 stale address 被继续使用。

### 1.3 InstructionBuilder

`InstructionBuilder` 负责把变量引用和维度参数封装成 `Instruction`：

```cpp
InstructionBuilder builder;
auto inst = builder.gemm(a, b, c, true);
```

目前支持：

- `abs(src, dst)`
- `layout_transpose(src, dst)`
- `layout_assemble(src, dst, offset_row, offset_col)`
- `reduce_add(src)`
- `reduce_cmp(src)`
- `gemm(a, b, c)`
- `mul(a, c, alpha)`
- `add(a, b, c)`
- `lut_sin(src, dst)`
- `lut_cos(src, dst)`
- `lut_softplus(src, dst)`
- `raw(...)`

Builder 会检查：

- 矩阵类指令是否带有 `rows`、`cols` 元数据。
- GEMM、ADD 等算子的维度是否匹配。
- 输出变量的 shape 是否符合该指令预期。
- 目标变量容量是否足够。
- command 维度字段是否能放入 12-bit field。

### 1.4 Instruction

`Instruction` 保存指令语义和最终 96-bit command：

```cpp
Instruction inst = runtime.gemm("A", "B", "C", true);
auto raw = inst.raw;
```

也可以展开为实际 config register 写入命令：

```cpp
for (const auto& write : inst.register_writes(0)) {
    device.write_register(write.reg_idx, write.value);
}
```

展开顺序为：

```text
cmdWord[core][0] = cmd[31:0]
cmdWord[core][1] = cmd[63:32]
cmdWord[core][2] = cmd[95:64]
cmdCtrl[core] = 1
cmdCtrl[core] = 0
```

这就是本层把计算指令封装成实际寄存器写命令的核心接口。

### 1.5 InstructionRuntime

`InstructionRuntime` 是推荐给上层使用的入口。它组合了 `Device`、
`VariableAllocator` 和 `InstructionBuilder`：

```cpp
auto device = dexmpc::runtime::Device::open_sim(argc, argv);
dexmpc::runtime::InstructionRuntime runtime(device);

runtime.reset_program();
runtime.reset_device();

runtime.allocate_matrix("A", dexsim::kMemGlobal, 16, 16);
runtime.allocate_matrix("B", dexsim::kMemLocal0, 16, 16);
runtime.allocate_matrix("C", dexsim::kMemTemp0, 16, 16);

auto inst = runtime.gemm("A", "B", "C", true);
runtime.send_and_wait_next(inst, 400000);
```

`InstructionRuntime` 暴露的生命周期接口：

```cpp
runtime.release_variable("tmp");
runtime.release("tmp2");
```

两者等价，都会调用内部 allocator 释放变量并回收 SRAM word 区间。

## 2. 变量访问方法

上层计算不直接传 SRAM 地址，而是传变量名：

```cpp
auto inst = runtime.add("lhs", "rhs", "out");
```

执行流程为：

1. `InstructionRuntime` 用变量名在 `VariableAllocator` 中查找 `VariableRef`。
2. `InstructionBuilder` 根据 `VariableRef` 的 SRAM 地址和形状生成 command fields。
3. `Instruction` 保存 raw 96-bit command 和寄存器写入序列。
4. `InstructionRuntime::send_instruction()` 通过设备访问层发送该 command。

这样高层只需要维护变量名，不需要理解 command bit layout 或 SRAM packed address。

## 3. 直接寄存器和 SRAM 接口

为了支持上层初始化数据写入和调试，`InstructionRuntime` 仍保留直接访问接口：

```cpp
runtime.write_register(reg_idx, value);
auto value = runtime.read_register(reg_idx);

runtime.write_memory(mem_id, word_addr, words);
auto words_readback = runtime.read_memory(mem_id, word_addr, word_count);
```

也可以按变量名读写已分配变量的 SRAM 区域：

```cpp
runtime.write_variable_words("A", packed_words);
auto out_words = runtime.read_variable_words("C");
```

这些接口不绕过地址检查。按变量名读写时会检查写入 word 数是否超过变量容量。

## 4. 示例流程

```cpp
#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_D2D

#include "dexmpc/runtime/instruction.hpp"

int main(int argc, char** argv) {
    using namespace dexmpc::runtime;

    auto device = Device::open_sim(argc, argv, Transport::D2D);
    InstructionRuntime runtime(device);

    runtime.reset_program();
    runtime.reset_device();

    auto a = runtime.allocate_matrix("A", dexsim::kMemGlobal, 16, 16);
    auto b = runtime.allocate_matrix("B", dexsim::kMemLocal0, 16, 16);
    auto c = runtime.allocate_matrix("C", dexsim::kMemTemp0, 16, 16);

runtime.write_variable_words(a.name, a_words);
runtime.write_variable_words(b.name, b_words);

auto gemm = runtime.gemm("A", "B", "C", true);
runtime.send_and_wait_next(gemm, 400000);

auto c_words = runtime.read_variable_words(c.name);

runtime.release_variable("A");
runtime.release_variable("B");
runtime.release_variable("C");
    return 0;
}
```

## 5. 验证记录

当前验证覆盖：

- 纯 C++ 指令层单元测试。
- D2D `InstructionRuntime` smoke。
- SPI `InstructionRuntime` smoke。
- D2D instruction mixed 全量 34 个 case。
- SPI instruction mixed 限量 8 个 case。
- D2D/SPI instruction mixed CSV 结果分析。

其中 D2D 全量 mixed 结果为 `overall: cases=34, pass=34, fail=0`。
SPI mixed 限量结果为 `overall: cases=8, pass=8, fail=0`。
