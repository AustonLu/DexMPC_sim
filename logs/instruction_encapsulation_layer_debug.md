# 指令封装层调试记录

日期：2026-06-03

## 1. 本次目标

本次实现 `docs/software stack/software_stack_layers_simple.md` 中的 C++ 指令封装层。
核心目标是把 ABS、Reduce、GEMM、MUL、ADD、DataLayout、LUT 等计算请求封装成
TopChip 可以执行的 96-bit command，并提供可展开为寄存器写入序列的接口。

同时需要：

- 保留直接寄存器和 SRAM 访问接口，供上层初始化数据和调试使用。
- 设计变量地址空间分配方法。
- 设计高层计算通过变量名访问底层 SRAM 地址的方法。
- 将 `software_stack/tests/cpp` 下的测试迁移到 instruction layer 接口。

## 2. 设计方案

### 2.1 指令封装

新增 `software_stack/include/dexmpc/runtime/instruction.hpp`。

主要对象：

- `VariableRef`：记录变量名、SRAM ID、word 地址、元素数量、word 数和矩阵形状。
- `VariableAllocator`：按 SRAM memory 分配变量地址，并维护变量名到地址的映射。
- `InstructionBuilder`：把变量和维度参数封装成 `Instruction`。
- `Instruction`：保存 opcode、subop、cmd_id、group_end 和 raw 96-bit command。
- `InstructionRuntime`：组合 `Device`、allocator 和 builder，给上层提供变量名级别接口。

`Instruction::register_writes(core)` 会展开为：

```text
cmdWord[core][0]
cmdWord[core][1]
cmdWord[core][2]
cmdCtrl[core] = 1
cmdCtrl[core] = 0
```

这满足“将计算指令封装成实际寄存器写命令”的要求。

### 2.2 变量地址空间分配

当前采用简单可预测的 per-memory monotonic allocator：

- Global、Local0、Temp0 等每个 `mem_id` 单独维护一个 `next_word`。
- 每个变量按 `ceil(elem_count / 8)` 个 128-bit word 分配。
- 自动分配变量之间保留 1 个 128-bit word gap，便于调试边界和重叠。
- 分配时检查 SRAM depth，超范围立即抛异常。
- 分配时检查与已有变量是否重叠。
- 变量名全局唯一。

对上层已经有固定 SRAM 地址的变量，提供：

- `bind_existing(name, mem_id, word_addr, elem_count, rows, cols)`
- `bind_existing_words(name, mem_id, word_addr, word_count)`

绑定成功后会推进对应 `mem_id` 的 `next_word`，避免后续自动分配覆盖手动绑定区域。

### 2.3 高层变量访问

上层计算通过变量名访问：

```cpp
auto inst = runtime.gemm("A", "B", "C", true);
```

内部流程：

1. `InstructionRuntime` 根据变量名查找 `VariableRef`。
2. `InstructionBuilder` 从 `VariableRef` 读取 packed address 和 shape。
3. Builder 检查维度和容量。
4. Builder 使用 `dexsim::make_cmd()` 生成 96-bit command。
5. Runtime 通过设备访问层发送 command 或返回寄存器写入序列。

Builder 同时检查输出变量 shape，例如 GEMM 的输出必须是 `A.rows x B.cols`，
Transpose 的输出必须是 `src.cols x src.rows`，Assemble 的写入区域不能超过目标矩阵。

## 3. 调试问题和修复

### 3.1 common-only 头文件仍依赖 Verilator

问题：

纯指令层单元测试只需要 command packing 和 SRAM 常量，但
`verification/verilator/cpp/common/dexmpc_sim.hpp` 在 `DEXMPC_SIM_COMMON_ONLY`
模式下仍无条件包含 `verilated.h`。这导致纯 C++ 测试必须额外带上 Verilator include。

修复：

将 `verilated.h` 放入 `#ifndef DEXMPC_SIM_COMMON_ONLY` 分支中。
common-only 模式现在不再依赖 Verilator 头文件。

### 3.2 手动绑定变量后可能发生地址重叠

问题：

初版 `bind_existing()` 只把变量名绑定到给定 SRAM 地址，没有推进 allocator 的
`next_word`。如果之后继续自动分配同一个 SRAM memory，可能覆盖已经绑定的变量。

修复：

- 新增重叠检查，所有自动分配和手动绑定都检查 `[word_addr, word_addr + word_count)`。
- `bind_existing()` 和 `bind_existing_words()` 成功后调用 `bump_next_word()` 推进游标。
- 新增单元测试覆盖绑定后分配游标推进，以及重叠绑定拒绝。

### 3.3 测试仍然绕过变量名级别接口

问题：

迁移初版的 mixed 测试虽然使用了 `InstructionBuilder`，但仍然直接把 `VariableRef`
传给 builder，没有覆盖高层通过变量名确定访问变量的路径。

修复：

将 mixed 测试中的指令构造改为：

```cpp
runtime_.gemm(a_ref.name, b_ref.name, c_ref.name)
runtime_.add(a_ref.name, b_ref.name, c_ref.name)
runtime_.reduce_add(src_ref.name)
```

这样测试会实际覆盖 `InstructionRuntime` 的变量名查找路径。

## 4. 验证结果

本次保留了每层独立 tb：

- backend/device 层原始 tb 保留原名：`test_sim_backend_*`、`test_device_mixed_*`。
- instruction encapsulation layer 新增独立 tb：`test_instruction_layer.cpp`、
  `test_instruction_runtime_*`、`test_instruction_mixed_*`。
- device mixed 结果保存在 `verification/results/software_stack/device_mixed`。
- instruction mixed 结果保存在 `verification/results/software_stack/instruction_mixed`。

已执行：

```text
/tmp/test_instruction_layer
/tmp/test_instruction_runtime_d2d
/tmp/test_instruction_runtime_spi
/tmp/test_instruction_mixed_d2d_full
/tmp/test_instruction_mixed_spi_smoke
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py --result-root verification/results/software_stack/instruction_mixed/d2d --out-dir verification/results/software_stack/instruction_mixed/d2d
python3 verification/results/core_top/mixed/analyze_tb_core_top_mixed.py --result-root verification/results/software_stack/instruction_mixed/spi --out-dir verification/results/software_stack/instruction_mixed/spi
```

结果：

- Instruction layer unit test passed。
- InstructionRuntime D2D smoke passed。
- InstructionRuntime SPI smoke passed。
- Instruction mixed D2D full passed，34 个 case，done_count=34。
- Instruction mixed SPI smoke passed，8 个 case，done_count=8。
- D2D instruction mixed CSV 分析：overall cases=34, pass=34, fail=0, exact=641/641。
- SPI instruction mixed CSV 分析：overall cases=8, pass=8, fail=0, exact=335/335。

说明：

SPI mixed 使用 pad-level SPI 访问，运行速度明显慢于 D2D。本次验证使用
`DEXMPC_DEVICE_MIXED_CASE_LIMIT=8` 覆盖所有 instruction kind 的 SPI smoke。
