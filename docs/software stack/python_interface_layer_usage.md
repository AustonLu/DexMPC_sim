# DexMPC Python 接口层设计与使用说明

本文档说明 DexMPC Python 接口层的设计原则、接口范围、使用方式和测试方法。该层对应
`software_stack_layers_simple.md` 中的 Python 接口层，位于 C++ 算子接口层之上。

当前实现文件：

```text
software_stack/python/dexmpc/runtime.py
software_stack/python/dexmpc/__init__.py
software_stack/python/cpp/dexmpc_python_binding.cpp
software_stack/python/build_python_bindings.py
```

当前测试文件：

```text
software_stack/tests/python/test_python_interface_layer.py
```

## 1. 设计原则

Python 接口层面向上层 MPC 应用，目标是让 Python 代码表达“做什么算子”，而不是表达“如何拼硬件命令”。

本层不负责：

- 拼 96-bit command。
- 维护 opcode、subop、packed SRAM address 等硬件 bit field。
- 直接实现硬件算子语义。

本层负责：

- 打开 D2D 或 SPI simulator。
- 暴露 Python 友好的 `Device` 和 `Tensor`。
- 上传、下载 matrix/vector/word 数据。
- 调用 C++ operator runtime 的同步算子接口。
- 提供少量调试用寄存器、SRAM 和 status pass-through。

硬件指令封装仍由 C++ 指令封装层完成，Python 只调用 operator-level API。

## 2. 构建方式

构建 D2D 和 SPI 两个 native module：

```bash
export VERILATOR_ROOT=/path/to/verilator/share/verilator
python3 software_stack/python/build_python_bindings.py --transport all
```

也可以只构建其中一个：

```bash
python3 software_stack/python/build_python_bindings.py --verilator-root /path/to/verilator/share/verilator --transport d2d
python3 software_stack/python/build_python_bindings.py --verilator-root /path/to/verilator/share/verilator --transport spi
```

构建产物位于：

```text
software_stack/python/dexmpc/_native_d2d*.so
software_stack/python/dexmpc/_native_spi*.so
```

## 3. 运行环境注意事项

当前 Anaconda Python 3.13 环境自带的 `libstdc++.so.6.0.29` 缺少 `GLIBCXX_3.4.30`，直接导入 native module 会失败。

在当前机器上运行 Python 测试或示例时，需要预加载系统 libstdc++：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport d2d
```

如果使用的 Python 环境已经带有足够新的 libstdc++，则不需要 `LD_PRELOAD`。

## 4. 基本用法

```python
import dexmpc

dev = dexmpc.open_sim("d2d")
dev.reset_program()
dev.reset_device()

matrix = [
    [0x3C00, 0x4000],
    [0x4200, 0x4400],
]

x = dev.upload_matrix(matrix, dev.mem_global, "x")
y = dev.abs(x, dev.mem_local0, "y")
result = dev.download_matrix(y)
```

SPI simulator 使用方式相同，只替换 transport：

```python
dev = dexmpc.open_sim("spi")
```

## 5. 数据对象

### Device

`Device` 是 Python 入口对象：

```python
dev = dexmpc.open_sim("d2d", timeout_cycles=1_200_000)
```

常用方法：

```python
dev.reset_program()
dev.reset_device()
dev.cycle()
dev.backend_kind()
dev.backend_transport()
dev.read_status()
```

SRAM memory id 可以通过属性取得：

```python
dev.mem_global
dev.mem_local0
dev.mem_temp0
```

### Tensor

`Tensor` 是 C++ `OperatorTensor` 的 Python handle。它不保存 Python 侧数据副本，而是引用 C++ runtime 中的 SRAM 分配。

常用查询：

```python
tensor.info
tensor.word_addr
tensor.valid()
```

`reset_program()` 会让旧 tensor 失效：

```python
x = dev.empty_matrix(dev.mem_global, 2, 2, "x")
dev.reset_program()
assert not x.valid()
```

## 6. 数据上传和下载

```python
x = dev.upload_matrix([[0x3C00, 0x4000]], dev.mem_global, "x")
values = dev.download_matrix(x)

v = dev.upload_vector([0x3C00, 0x3C00, 0x3C00, 0x3C00], dev.mem_temp0, "v")
out = dev.download_vector(v)

w = dev.upload_words([(1, 2, 3, 4)], dev.mem_local0, "w")
words = dev.download_words(w)
```

也可以创建空 tensor 后写入：

```python
x = dev.empty_words(dev.mem_global, 1, "x")
dev.write_words(x, [(0x00010002, 0x00030004, 0, 0)])
```

## 7. 算子接口

当前 Python 层暴露的算子接口与 C++ operator layer 对齐：

```python
y = dev.abs(x, dst_mem, "y")
t = dev.transpose(x, dst_mem, "t")

assembled = dev.layout_assemble(src, dst_mem, dst_rows, dst_cols, off_r, off_c, "assembled")
dev.layout_assemble_into(src, dst, off_r, off_c)

c = dev.gemm(a, b, dst_mem, "c")
z = dev.add(a, b, dst_mem, "z")
scaled = dev.mul(a, 0x3C00, dst_mem, "scaled")

s = dev.lut_sin(x, dst_mem, "sin")
c = dev.lut_cos(x, dst_mem, "cos")
p = dev.lut_softplus(x, dst_mem, "softplus")

sum_result = dev.reduce_add(v)
min_result = dev.reduce_cmp(v)
```

`reduce_add()` 和 `reduce_cmp()` 返回 dict：

```python
{"value": 0x4800, "index": 0}
```

## 8. 调试接口

为支持 backend smoke 和调试，本层保留寄存器和 SRAM pass-through：

```python
dev.write_register(reg_idx, value)
value = dev.read_register(reg_idx)

dev.write_memory(mem_id, word_addr, [(1, 2, 3, 4)])
words = dev.read_memory(mem_id, word_addr, 1)

status = dev.read_status()
```

这些接口用于验证和调试，不建议上层 MPC 应用依赖具体寄存器编号。

## 9. 测试方式

D2D 全量 Python interface 测试：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport d2d
```

SPI 测试建议使用较小 mixed case 数，因为 pad-level SPI simulation 明显慢于 D2D：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport spi --mixed-case-limit 8
```

也可以同时测试两个 transport：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport all --mixed-case-limit 8
```

## 10. 当前验证结果

截至 2026-06-04：

- D2D full Python interface test 已通过。
- SPI Python interface test 在 `--mixed-case-limit 8` 下已通过。
- SPI 34-case full mixed sequence 在 20 分钟命令超时前未完成，因此当前不记录为通过。

## 11. 后续扩展方向

- 为 native module 增加 wheel 或 setup 配置，减少手动 `PYTHONPATH` 使用。
- 解决 Anaconda libstdc++ 版本冲突，例如统一运行环境或调整链接策略。
- 根据上层 MPC 应用需求增加更贴近算法的数据结构，但仍保持 Python 不拼硬件 command。
