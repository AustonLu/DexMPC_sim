# DexMPC 算子接口层接口说明

本文档说明 C++ 算子接口层的设计原则、接口和使用方式。该层对应
`docs/software stack/software_stack_layers_simple.md` 中的 Layer 4，位于 C++
指令封装层之上。

当前实现文件：

```text
software_stack/include/dexmpc/runtime/operator.hpp
```

当前测试文件：

```text
software_stack/tests/cpp/test_operator_layer.cpp
software_stack/tests/cpp/test_operator_runtime_d2d.cpp
software_stack/tests/cpp/test_operator_runtime_spi.cpp
software_stack/tests/cpp/test_operator_mixed_common.hpp
software_stack/tests/cpp/test_operator_mixed_d2d.cpp
software_stack/tests/cpp/test_operator_mixed_spi.cpp
```

## 1. 层级职责

算子接口层把硬件指令进一步包装成高层算子。上层不再直接写 opcode、subop、
SRAM packed address 或 96-bit command，而是调用：

```cpp
runtime.gemm(a, b, dst_mem);
runtime.abs(x, dst_mem);
runtime.layout_transpose(x, dst_mem);
runtime.reduce_add(x);
```

内部执行流程：

1. 检查输入 `OperatorTensor` 是否仍然 live。
2. 检查矩阵 shape 或 vector 长度是否符合算子要求。
3. 为输出变量分配 SRAM 地址空间。
4. 调用 instruction layer 生成硬件 command。
5. 通过 device layer 发送 command。
6. 等待当前 command 完成。
7. 返回新的 `OperatorTensor` 或 `ReduceResult`。

## 2. 核心对象

### 2.1 OperatorRuntime

`OperatorRuntime` 是本层入口：

```cpp
auto device = dexmpc::runtime::Device::open_sim(argc, argv, dexmpc::runtime::Transport::D2D);
dexmpc::runtime::OperatorRuntime runtime(device);

runtime.reset_program();
runtime.reset_device();
```

构造参数：

```cpp
explicit OperatorRuntime(Device& device, int timeout_cycles = 1200000);
```

`timeout_cycles` 用于每条同步算子指令的等待超时。

### 2.2 OperatorTensor

`OperatorTensor` 表示一个已经分配或绑定到 SRAM 的变量。它保存：

- 变量名。
- SRAM memory id。
- 128-bit word 起始地址。
- word 数量。
- element 数量。
- matrix shape。

常用查询接口：

```cpp
tensor.name();
tensor.mem_id();
tensor.word_addr();
tensor.word_count();
tensor.elem_count();
tensor.rows();
tensor.cols();
tensor.is_matrix();
tensor.valid();
```

`OperatorTensor` 是 move-only 对象，禁止 copy。算子调用时通常传 `const OperatorTensor&`。

### 2.3 ReduceResult

Reduce 类算子直接返回标量结果：

```cpp
struct ReduceResult {
    std::uint16_t value;
    std::uint16_t index;
    StatusRegisters status;
};
```

`reduce_add()` 使用 `value`，`index` 固定为 0。
`reduce_cmp()` 使用 `value` 和 `index`，分别表示比较结果和索引。

## 3. 数据接口

### 3.1 创建空变量

```cpp
auto a = runtime.empty_matrix(dexsim::kMemGlobal, 16, 16, "A");
auto v = runtime.empty_vector(dexsim::kMemTemp0, 32, "v");
auto raw = runtime.empty_words(dexsim::kMemLocal0, 4, "raw");
```

如果不传名称，runtime 会自动生成名称。

### 3.2 上传数据

```cpp
dexsim::Matrix matrix = dexsim::make_matrix(16, 16);
auto a = runtime.upload_matrix(matrix, dexsim::kMemGlobal, "A");

std::vector<std::uint16_t> values(8, 0x3c00);
auto v = runtime.upload_vector(values, dexsim::kMemTemp0, "v");

std::vector<dexmpc::runtime::Word128> words{dexsim::zero_word()};
auto raw = runtime.upload_words(words, dexsim::kMemLocal0, "raw");
```

### 3.3 下载数据

```cpp
auto matrix_out = runtime.download_matrix(a);
auto vector_out = runtime.download_vector(v);
auto words_out = runtime.download_words(raw);
```

下载前会检查 tensor 是否仍然 live。

### 3.4 写入已分配变量

```cpp
runtime.write_words(a, dexsim::matrix_to_words(matrix, a.rows(), a.cols()));
```

### 3.5 直接寄存器和 SRAM 接口

为支持初始化数据写入和调试，operator layer 保留以下 pass-through 接口：

```cpp
runtime.write_register(reg_idx, value);
auto value = runtime.read_register(reg_idx);

runtime.write_memory(mem_id, word_addr, words);
auto words = runtime.read_memory(mem_id, word_addr, word_count);
```

也可以先直接写 SRAM，再把该区域绑定为 operator tensor：

```cpp
runtime.write_memory(dexsim::kMemGlobal, 64, words);
auto input = runtime.bind_existing_matrix(dexsim::kMemGlobal, 64, 16, 16, "input");
```

可用绑定接口：

```cpp
runtime.bind_existing_matrix(mem_id, word_addr, rows, cols, name);
runtime.bind_existing_vector(mem_id, word_addr, elem_count, name);
runtime.bind_existing_words(mem_id, word_addr, word_count, name);
```

绑定接口只管理 allocator 中的占用关系，不会写入或清空 SRAM 内容。

## 4. 算子接口

当前支持：

```cpp
auto y = runtime.abs(x, dst_mem, "y");
auto t = runtime.layout_transpose(x, dst_mem, "t");
auto assembled = runtime.layout_assemble(src, dst_mem, dst_rows, dst_cols, off_r, off_c, "assembled");
runtime.layout_assemble_into(src, dst, off_r, off_c);

auto sum = runtime.reduce_add(x);
auto min_result = runtime.reduce_cmp(x);

auto c = runtime.gemm(a, b, dst_mem, "c");
runtime.gemm_into(a, b, c);

auto scaled = runtime.mul(a, alpha_fp16, dst_mem, "scaled");
auto z = runtime.add(a, b, dst_mem, "z");

auto s = runtime.lut_sin(x, dst_mem, "s");
auto c2 = runtime.lut_cos(x, dst_mem, "c2");
auto p = runtime.lut_softplus(x, dst_mem, "p");
```

所有算子当前都是同步接口：发送一条指令后等待该指令完成再返回。

## 5. 变量生命周期和自动释放

本层使用 C++ RAII 管理 SRAM 变量生命周期。

```cpp
int released_addr = -1;
{
    auto tmp = runtime.abs(input, dexsim::kMemLocal0, "tmp");
    released_addr = tmp.word_addr();
    auto result = runtime.download_matrix(tmp);
} // tmp 离开作用域，自动释放 SRAM 地址空间

auto reused = runtime.empty_matrix(dexsim::kMemLocal0, 2, 4, "reused");
```

当 `tmp` 析构时，其变量名会从 instruction layer allocator 中释放，对应 SRAM word 区间进入 free-list。
后续分配可以复用这段地址。

### 5.1 为什么不暴露 unload

operator layer 的目标是让上层专注于算子调用，而不是手动管理 SRAM 地址空间。
显式 unload 容易在异常路径或复杂临时变量链中遗漏。本层使用对象生命周期表达变量生命周期：

- 临时变量离开作用域自动释放。
- 函数返回值通过 move 转移所有权。
- C++ 异常展开时仍会执行析构释放。

### 5.2 move-only 语义

`OperatorTensor` 禁止 copy：

```cpp
auto a = runtime.upload_matrix(matrix, dexsim::kMemGlobal, "A");
auto b = std::move(a);
```

move 后，源 tensor 变为 invalid。这样可以避免同一个 SRAM 变量被两个 handle 同时拥有并重复释放。

算子函数接收 `const OperatorTensor&`，不会转移输入变量所有权。

### 5.3 reset_program 语义

```cpp
auto a = runtime.empty_matrix(dexsim::kMemGlobal, 4, 4, "A");
runtime.reset_program();
```

`reset_program()` 会清空 instruction layer allocator，并递增 runtime generation。旧 tensor 会变为 invalid，
析构时不会再次释放已经清空的 allocator。旧 tensor 不能再用于算子调用或下载。

## 6. 设计方法

本层不重新实现地址分配或指令拼装，而是复用 instruction layer：

- 变量地址空间分配：由 `VariableAllocator` 管理。
- 变量名到 SRAM 地址映射：由 `InstructionRuntime` 管理。
- 指令封装：由 `InstructionBuilder` 完成。
- 设备访问：通过 `Device` 统一进入 backend。

operator layer 增加的核心能力是：

- 用 `OperatorTensor` 作为变量访问 handle。
- 用 RAII 自动释放变量空间。
- 在算子入口进行 live-handle 和 shape 检查。
- 把 upload/operator/download 组织成更接近上层算法的接口。

## 7. 示例

```cpp
#define DEXMPC_ENABLE_TOPCHIP_SIM_BACKEND
#define DEX_TOPCHIP_TRANSPORT_D2D

#include "dexmpc/runtime/operator.hpp"

int main(int argc, char** argv) {
    using namespace dexmpc::runtime;

    auto device = Device::open_sim(argc, argv, Transport::D2D);
    OperatorRuntime runtime(device);

    runtime.reset_program();
    runtime.reset_device();

    dexsim::Matrix a = dexsim::make_matrix(16, 16);
    dexsim::Matrix b = dexsim::make_matrix(16, 16);

    auto a_tensor = runtime.upload_matrix(a, dexsim::kMemGlobal, "A");
    auto b_tensor = runtime.upload_matrix(b, dexsim::kMemLocal0, "B");

    auto c_tensor = runtime.gemm(a_tensor, b_tensor, dexsim::kMemTemp0, "C");
    auto c = runtime.download_matrix(c_tensor);

    return 0;
}
```

## 8. 测试说明

operator layer 使用独立 tb，不覆盖原 backend/device/instruction layer tb。

建议最小回归：

```text
test_operator_layer.cpp
test_operator_runtime_d2d.cpp
test_operator_runtime_spi.cpp
test_operator_mixed_d2d.cpp
test_operator_mixed_spi.cpp
```

SPI mixed 测试运行时间明显长于 D2D。日常 smoke 可以使用
`DEXMPC_OPERATOR_MIXED_CASE_LIMIT=8` 限制前 8 个 case，覆盖主要算子类型。
