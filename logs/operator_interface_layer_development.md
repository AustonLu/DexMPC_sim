# 算子接口层开发与调试记录

日期：2026-06-03

## 1. 目标

本次开发 `docs/software stack/software_stack_layers_simple.md` 中的 Layer 4：
C++ 算子接口层。该层位于指令封装层之上，向上暴露 `gemm()`、`abs()`、
`layout_transpose()`、`reduce_add()` 等算子级接口，内部负责调用
`InstructionRuntime` 生成并发送硬件 96-bit command。

本次还需要重点处理变量生命周期结束后的自动释放问题，使 operator layer 的使用者不需要显式
`unload()` 或 `release()` 变量内存。

## 2. 生命周期自动释放方案分析

### 2.1 方案一：继续暴露显式 unload

优点是实现简单，变量什么时候释放完全由调用者决定。缺点是上层每个算子序列都必须手动写
`release()`，很容易遗漏，尤其是在异常路径和未来 Python binding 中更容易造成 SRAM 地址空间泄漏。

这个方案不符合本层目标：operator interface layer 应该屏蔽 SRAM 生命周期细节。

### 2.2 方案二：基于共享引用计数自动释放

可以让多个 tensor handle 指向同一个变量，最后一个引用析构时释放 SRAM。这个方案适合需要别名、
视图、切片或复杂图结构的系统。

当前阶段的问题是：硬件变量没有实现 view 语义，多个可写 handle 指向同一区域反而容易导致所有权不清。
如果一份变量被复制到多个对象，测试也更难判断是否发生了重复释放或 stale handle 使用。

### 2.3 方案三：C++ RAII + move-only tensor handle

当前实现采用该方案。

核心设计：

- `OperatorRuntime` 负责持有 `InstructionRuntime` 和变量 allocator。
- 每个上层变量用 `OperatorTensor` 表示。
- `OperatorTensor` 是 move-only 对象，禁止 copy。
- `OperatorTensor` 析构时自动调用 `InstructionRuntime::release_variable()`。
- move 构造和 move 赋值会转移所有权，避免同一变量被释放两次。
- `OperatorRuntime::reset_program()` 会递增 generation，旧 tensor 立即变为 invalid，析构时不会再释放已经清空的 allocator。
- `OperatorRuntime` 析构时会把 shared state 标记为 inactive，防止 tensor 比 runtime 晚析构时访问悬空指针。

选择理由：

- C++ 对象生命周期和 SRAM 分配生命周期一一对应，语义直接。
- 栈上临时变量离开作用域即可释放并进入 allocator free-list，能自动复用地址空间。
- move-only 明确表达唯一所有权，降低重复释放风险。
- 异常路径下析构仍会触发释放，比显式 unload 更稳健。

### 2.4 长期方案：compiler last-use 分析

如果后续实现计算图、IR、scheduler 或 operator fusion，更好的内存回收策略可能是 last-use analysis：
编译器在生成算子序列时静态判断每个中间变量最后一次使用点，并在该点之后释放或复用空间。

当前 operator layer 面向手写 C++/Python 算子调用，不维护全局计算图，因此先采用 RAII。未来 compiler
可以在更高层生成临时 `OperatorTensor`，仍然复用本层 RAII 机制；如果需要更细粒度控制，再添加内部
allocator planning 接口。

## 3. 当前设计

实现文件：

```text
software_stack/include/dexmpc/runtime/operator.hpp
```

主要类型：

- `OperatorRuntime`：operator layer 入口，组合 `InstructionRuntime`，提供数据上传、下载、算子执行和底层调试接口。
- `OperatorTensor`：变量 handle，保存变量名、SRAM 地址、shape 和自动释放所有权。
- `ReduceResult`：reduce 指令返回值，包含 result value、index 和 status register snapshot。

变量分配仍复用 instruction layer 的 `VariableAllocator`：

- 每个 SRAM memory 独立维护地址空间。
- 按 128-bit word 分配。
- 已释放区间进入 free-list 并可被后续变量复用。
- operator layer 通过 RAII 自动调用 release，把释放动作从用户代码中移除。

operator layer 还保留了直接寄存器和 SRAM 访问接口：

- `write_register()`、`read_register()`
- `write_memory()`、`read_memory()`
- `bind_existing_matrix()`、`bind_existing_vector()`、`bind_existing_words()`

这些接口用于初始化数据、调试或绑定已经写入 SRAM 的区域。绑定后返回的仍是 `OperatorTensor`，其生命周期结束时会释放 allocator 对该区域的占用记录，但不会清空 SRAM 内容。

## 4. 开发与调试过程

1. 阅读 `software_stack_layers_simple.md`，确认 Layer 4 的职责是把指令层进一步封装成算子，并执行等待。
2. 阅读 `instruction.hpp`，确认 instruction layer 已经提供变量名查找、allocator、command builder、寄存器写入序列和设备发送接口。
3. 新增 `operator.hpp`，让 `OperatorRuntime` 持有 `InstructionRuntime`，并在每个算子 API 内部完成：
   输入 tensor 存活检查、shape 检查、输出 tensor 分配、指令生成、发送和等待完成。
4. 设计 `OperatorTensor` 为 move-only RAII handle，析构自动释放变量地址空间。
5. 增加 generation guard，解决 `reset_program()` 后旧 tensor 析构再次释放未知变量的问题。
6. 增加 runtime active guard，解决 tensor 生命周期长于 runtime 时潜在的悬空访问问题。
7. 从现有 mixed 测试迁移出 operator layer 专用测试，避免覆盖 backend/device/instruction 层原始 tb。
8. 检查接口完整性时发现 `gemm_into()` 只检查输出 tensor，没有在 operator 层入口处检查两个输入 tensor 的 live/shape；已补齐输入检查。
9. 按需求补充直接寄存器和 SRAM pass-through 接口，并新增 bind-existing 接口，支持上层先写原始 SRAM 再绑定为 operator tensor。
10. 单元测试 fake backend 初版只返回零，不能有效验证 pass-through；已改为记录寄存器和 SRAM 写入并读回检查。

## 5. 测试覆盖

新增 operator layer 独立测试：

```text
software_stack/tests/cpp/test_operator_layer.cpp
software_stack/tests/cpp/test_operator_runtime_d2d.cpp
software_stack/tests/cpp/test_operator_runtime_spi.cpp
software_stack/tests/cpp/test_operator_mixed_common.hpp
software_stack/tests/cpp/test_operator_mixed_d2d.cpp
software_stack/tests/cpp/test_operator_mixed_spi.cpp
```

覆盖内容：

- RAII scope exit 后自动释放变量。
- 释放后的 SRAM word 地址复用。
- move-only handle 转移所有权且不重复释放。
- `reset_program()` 后旧 tensor invalid。
- 直接寄存器/SRAM pass-through。
- bind-existing 区域绑定、释放和复用。
- D2D/SPI simulator 上的 `upload_matrix -> abs -> download_matrix` smoke。
- operator mixed 测试覆盖 abs、transpose、assemble、reduce_add、reduce_cmp、gemm、mul、add。

## 6. 注意事项

- `OperatorTensor` 析构函数不会抛异常；释放失败会被吞掉。这是 C++ 析构函数的安全要求。
- operator layer 不暴露显式 unload。需要提前释放时，让 `OperatorTensor` 离开作用域或 move 赋值为其他 tensor。
- `OperatorTensor` 禁止 copy。需要传递所有权时使用 move；只读使用时传 `const OperatorTensor&`。
- `reset_program()` 会清空 allocator，并使旧 tensor invalid。旧 tensor 不应再参与算子调用。
- operator layer 仍允许访问 `instruction_runtime()`，但不建议手动释放 operator-owned tensor 对应的变量名，否则会破坏 RAII 所有权假设。

## 7. 验证记录

最终回归已完成：

```text
g++ -std=c++17 -Isoftware_stack/include -Iverification/verilator/cpp/common \
  software_stack/tests/cpp/test_operator_layer.cpp -o /tmp/test_operator_layer
/tmp/test_operator_layer
```

结果：

```text
Operator layer unit test passed
```

```text
g++ -std=c++17 \
  -Isoftware_stack/include -Isoftware_stack/tests/cpp -Iverification/verilator/cpp/common \
  -Ibuild/verilator/full_chip/topchip_d2d_mixed_tb \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/vltstd \
  software_stack/tests/cpp/test_operator_runtime_d2d.cpp \
  build/verilator/full_chip/topchip_d2d_mixed_tb/VTopChipTopD2dHarness__ALL.a \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated.cpp \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated_threads.cpp \
  -pthread -o /tmp/test_operator_runtime_d2d
/tmp/test_operator_runtime_d2d
```

结果：

```text
OperatorRuntime D2D smoke passed at cycle 1821
```

```text
g++ -std=c++17 \
  -Isoftware_stack/include -Isoftware_stack/tests/cpp -Iverification/verilator/cpp/common \
  -Ibuild/verilator/full_chip/topchiptop_legacy_spi_tb \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/vltstd \
  software_stack/tests/cpp/test_operator_runtime_spi.cpp \
  build/verilator/full_chip/topchiptop_legacy_spi_tb/VTopChipTop__ALL.a \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated.cpp \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated_threads.cpp \
  -pthread -o /tmp/test_operator_runtime_spi
/tmp/test_operator_runtime_spi
```

结果：

```text
OperatorRuntime SPI smoke passed at cycle 25612
```

```text
g++ -std=c++17 \
  -Isoftware_stack/include -Isoftware_stack/tests/cpp -Iverification/verilator/cpp/common \
  -Ibuild/verilator/full_chip/topchip_d2d_mixed_tb \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/vltstd \
  software_stack/tests/cpp/test_operator_mixed_d2d.cpp \
  build/verilator/full_chip/topchip_d2d_mixed_tb/VTopChipTopD2dHarness__ALL.a \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated.cpp \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated_threads.cpp \
  -pthread -o /tmp/test_operator_mixed_d2d_full
/tmp/test_operator_mixed_d2d_full
```

结果：

```text
Operator mixed D2D test passed at cycle 59112, cases=34
```

```text
g++ -std=c++17 -DDEXMPC_OPERATOR_MIXED_CASE_LIMIT=8 \
  -DDEXMPC_OPERATOR_MIXED_TIMEOUT_CYCLES=20000 \
  -Isoftware_stack/include -Isoftware_stack/tests/cpp -Iverification/verilator/cpp/common \
  -Ibuild/verilator/full_chip/topchiptop_legacy_spi_tb \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include \
  -I/home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/vltstd \
  software_stack/tests/cpp/test_operator_mixed_spi.cpp \
  build/verilator/full_chip/topchiptop_legacy_spi_tb/VTopChipTop__ALL.a \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated.cpp \
  /home/ljj/dex_cycle_model/tools/verilator/share/verilator/include/verilated_threads.cpp \
  -pthread -o /tmp/test_operator_mixed_spi_smoke
/tmp/test_operator_mixed_spi_smoke
```

结果：

```text
Operator mixed SPI test passed at cycle 441588, cases=8
```

说明：SPI mixed smoke 使用 pad-level SPI，运行明显慢于 D2D。第一次使用 360 秒工具超时被截断，
未出现功能错误；使用 900 秒超时重跑后通过。
