# DexSim 低层全算子 Python SDK 安装与使用手册

> 本文是 v0.2 低层 `Session`/command 兼容手册，这些接口在 v0.4.1 继续兼容。普通软件和 M7 kernel 开发应使用免地址的高层 API，见 `docs/v0.4.1_resident_kernel_sdk.md`。

文档对应版本：`dexmpc-sim 0.2.0`
适用代码分支：`DexMPC_sim/compiler`
目标平台：Linux x86-64
硬件路径：TopChip D2D cycle-accurate Verilator simulator，command context/core0

## 1. SDK 的用途和边界

该 Python 包把 DexMPC 芯片当前 RTL 中 core0 可用的全部硬件基本算子封装成稳定 API。上层软件只需准备 FP16 tensor、规划 SRAM 地址、构造命令并调用 `Session.run()`，不需要手写 opcode、subop 或 96-bit command。

当前正式支持 11 个硬件 primitive：

| 类别 | Python API | 功能 |
|---|---|---|
| ABS | `dexsim.abs` | 逐元素清除 FP16 符号位 |
| Reduce | `dexsim.add_reduce` | FP16 加法树归约 |
| Reduce | `dexsim.compare_reduce` | FP16 最小值及索引归约 |
| LA | `dexsim.gemm` | FP16 矩阵乘法 |
| LA | `dexsim.scale` | tensor 乘 FP16 标量 |
| LA | `dexsim.add` | 同 shape tensor 逐元素加法 |
| LUT | `dexsim.sin` | FP16 Sin LUT |
| LUT | `dexsim.cos` | FP16 Cos LUT |
| LUT | `dexsim.softplus` | FP16 Softplus LUT |
| DataLayout | `dexsim.assemble` | 将源矩阵写入目标矩阵的偏移区域 |
| DataLayout | `dexsim.transpose` | 矩阵转置 |

另外提供 3 个由 GEMM 硬件直接表达的正式便捷接口：

- `dexsim.gemv`：`M=1` 的 GEMM；
- `dexsim.dot`：`N=M=1` 的 GEMM；
- `dexsim.outer`：`K=1` 的 GEMM。

为兼容旧软件栈，还保留以下别名：

| 推荐名称 | 兼容名称 |
|---|---|
| `add_reduce` | `reduce_add` |
| `compare_reduce` | `reduce_cmp` |
| `scale` | `mul` |
| `sin` | `lut_sin` |
| `cos` | `lut_cos` |
| `softplus` | `lut_softplus` |
| `assemble` | `layout_assemble` |
| `transpose` | `layout_transpose` |

当前版本有意限制为：

- 只开放 `transport="d2d"`；
- 只开放 `cores=[0]` 和 `core=0`；
- 一个 `Session` 内只有一个持久 Verilator model，构造时 reset 一次；
- 不提供自动 SRAM allocator、tensor 生命周期管理、tiling、mixed-kernel compiler 或多核调度；
- 未验证的输入/输出 SRAM 重叠（in-place）会在命令构造阶段被拒绝；
- SPI 和多核 runtime 不属于该版本范围。

## 2. 安装前提

构建 wheel 时会在本机重新 Verilate 完整 TopChip，因此需要：

- Linux x86-64；
- Python 3.9 或更高版本；
- Verilator；
- CMake 3.20 或更高版本；
- GNU Make；
- 支持 C++17 的 C++ 编译器；
- pthread 和 libatomic。

Python 构建过程不依赖 NumPy、setuptools、wheel、pybind11、nanobind 或 scikit-build-core，也不需要联网下载构建依赖。

在项目远程服务器上的已知环境为：

```sh
ssh apple.local
cd ~/Workspace/DexMPC_post_to/DexMPC_sim

~/miniforge3/bin/conda run -n dexsim_verilator python --version
~/miniforge3/bin/conda run -n dexsim_verilator verilator --version
~/miniforge3/bin/conda run -n dexsim_verilator cmake --version
```

## 3. 安装方法

### 3.1 安装到当前 Python 环境

```sh
cd ~/Workspace/DexMPC_post_to/DexMPC_sim

~/miniforge3/bin/conda run -n dexsim_verilator \
  python -m pip install \
  --disable-pip-version-check \
  --no-deps \
  --no-build-isolation \
  .
```

### 3.2 安装到隔离目录，推荐用于验收

```sh
rm -rf /tmp/dexsim-sdk-0.2.0

~/miniforge3/bin/conda run -n dexsim_verilator \
  python -m pip install \
  --disable-pip-version-check \
  --no-deps \
  --no-build-isolation \
  --target /tmp/dexsim-sdk-0.2.0 \
  .
```

从隔离目录导入：

```sh
cd /tmp
PYTHONPATH=/tmp/dexsim-sdk-0.2.0 \
  ~/miniforge3/bin/conda run -n dexsim_verilator \
  python -c 'import dexsim; print(dexsim.__version__); print(dexsim.Session.capabilities())'
```

第一次构建需要生成完整 Verilated model，通常需要数分钟，并可能消耗较多内存。生成的 wheel 是包含 native shared library 的 Linux x86-64 平台 wheel，不是跨平台 pure-Python wheel。

## 4. 两种地址单位必须严格区分

这是使用 SDK 时最容易出错的地方。

### 4.1 Tensor I/O 使用 FP16 element offset

`write_tensor()`、`read_tensor()`、`write_tensor_bits()` 和 `read_tensor_bits()` 的 `offset` 单位都是一个 FP16 元素，即 16 bit。

```python
session.write_tensor(memory="local", offset=8, value=[1.0, 2.0])
```

这里从 Local0 的第 8 个 FP16 element 开始写，即第 1 个 128-bit word 的开头。

### 4.2 Command builder 使用 128-bit word offset

所有命令构造器的 `*_word_offset` 单位都是 128-bit SRAM word。每个 word 包含 8 个 FP16 元素。

```python
dexsim.abs(
    1,
    src_memory="local",
    src_word_offset=1,
    out_memory="temp",
    out_word_offset=2,
    rows=1,
    cols=2,
)
```

该命令从 Local0 element offset `1 * 8 = 8` 读取，并从 Temp0 element offset `2 * 8 = 16` 开始写。

### 4.3 可用 SRAM

| Python 名称 | command SRAM ID | physical SRAM | word 深度 | FP16 element 容量 |
|---|---:|---|---:|---:|
| `global` | 0 | Global SRAM | 2048 | 16384 |
| `local` | 1 | Local0 SRAM | 512 | 4096 |
| `temp` | 2 | Temp0 SRAM | 896 | 7168 |

Builder 会根据 shape 检查完整输入/输出区域，而不仅检查首地址。越界会在命令提交前抛出 `ValueError`。

## 5. 最小端到端示例

```python
import dexsim

with dexsim.Session(
    transport="d2d",
    cores=[0],
    timeout_cycles=400_000,
) as session:
    # Tensor offset 以 FP16 element 计。
    session.write_tensor(
        memory="local",
        offset=0,
        value=[[1.0, 2.0], [3.0, 4.0]],
    )
    session.write_tensor(
        memory="local",
        offset=8,
        value=[[5.0, 6.0], [7.0, 8.0]],
    )

    # Command offset 以 128-bit word 计。
    command = dexsim.gemm(
        1,
        a_memory="local",
        a_word_offset=0,
        b_memory="local",
        b_word_offset=1,
        out_memory="local",
        out_word_offset=2,
        n_rows=2,
        m_cols=2,
        k_dim=2,
    )

    trace = session.run([command])
    output = session.read_tensor(
        memory="local",
        offset=16,
        shape=(2, 2),
    )

    print(output)
    # [[19.0, 22.0], [43.0, 50.0]]
    print(trace.to_dict())
```

`command_id` 必须是 `0..4095` 的整数。推荐在一个编译或调度批次内使用唯一且递增的 ID，以便定位错误和对应逐命令结果。

## 6. FP16 浮点 I/O 与原始 bit I/O

### 6.1 普通浮点接口

```python
session.write_tensor(
    memory="global",
    offset=3,
    value=[[1.0, -2.0], [0.25, 8.0]],
)

value = session.read_tensor(
    memory="global",
    offset=3,
    shape=(2, 2),
)
```

写入时每个 Python 数值都会量化为 FP16；读出时返回 Python float 或嵌套 list。

### 6.2 Bit-exact 接口

验证 NaN payload、Inf、正负零、subnormal、LUT 边界或编译器常量编码时，应使用原始 16-bit 接口：

```python
raw = [0x0000, 0x8000, 0x3C00, 0xBC00, 0x7C00, 0x7E55]

session.write_tensor_bits(
    memory="temp",
    offset=3,
    value=raw,
)

readback = session.read_tensor_bits(
    memory="temp",
    offset=3,
    shape=(len(raw),),
)

assert readback == raw
```

辅助函数：

```python
alpha_bits = dexsim.fp16_bits(-0.5)
alpha_value = dexsim.fp16_value(alpha_bits)
```

Bit I/O 的每个输入必须是 `0..0xFFFF` 的整数。

## 7. Session 和 batch 执行

```python
with dexsim.Session() as session:
    trace = session.run([
        command_0,
        command_1,
        command_2,
    ])
```

当前 runtime 在同一个 `run()` 中顺序提交、逐条等待并验收命令，因此：

- 命令完成顺序与输入 list 顺序一致；
- 前一条命令的输出可以作为后一条命令的输入；
- 每条命令都检查 `lastDone` 中的 command ID、opcode、subop、group_end 和 illegal bit；
- timeout 会抛出 `dexsim.DexSimError`；
- 一个正常 `Session` 生命周期内 `reset_count` 始终为 1。

`group_end` 会进入硬件 command 和完成元数据，默认值为 `True`。当前 SDK 不根据该位自动改变 batch 的提交策略，后续编译器可以使用它标记逻辑 kernel 边界。

## 8. RunResult 和逐命令结果

`Session.run()` 返回 `RunResult`：

| 字段 | 含义 |
|---|---|
| `cycles` | 本次命令执行消耗的仿真周期，不含首次 LUT setup |
| `read_bytes` | 本次命令执行产生的 D2D 逻辑读 payload |
| `write_bytes` | 本次命令执行产生的 D2D 逻辑写 payload |
| `command_count` | 命令数 |
| `done_count_before/after` | 执行前后的硬件完成计数 |
| `last_done` | 最后一条命令的原始 lastDone 寄存器 |
| `reset_count` | Session 中 simulator reset 次数 |
| `command_results` | 与输入命令一一对应的 `CommandResult` tuple |
| `setup_cycles` | 本次调用前自动加载 LUT 的周期 |
| `setup_read_bytes` | LUT setup 的逻辑读 payload |
| `setup_write_bytes` | LUT setup 的逻辑写 payload |
| `total_cycles` | `setup_cycles + cycles` |
| `total_read_bytes` | setup 与执行读 payload 之和 |
| `total_write_bytes` | setup 与执行写 payload 之和 |

每个 `CommandResult` 包含：

- `command_id`；
- `opcode`、`subop`；
- `group_end`；
- `done_cycle`，硬件完成该命令时记录的绝对 cycle；
- `reduce_value` 和 `reduce_value_bits`；
- Compare-Reduce 的 `reduce_index`；
- `reduce_valid`。

非 Reduce 命令的 Reduce 相关字段为 `None` 或 `False`。

## 9. 多条 Reduce 放在同一个 batch

0.2.0 会在每一条 Reduce 完成后立即从硬件结果寄存器采集结果，因此前面的结果不会被后面的 Reduce 覆盖。

```python
import dexsim

values_a = [3.0, -1.0, 2.0, -2.0]
values_b = [1.0, 2.0, 3.0, 4.0]

with dexsim.Session() as session:
    session.write_tensor(memory="global", offset=0, value=values_a)
    session.write_tensor(memory="local", offset=0, value=values_b)

    trace = session.run([
        dexsim.add_reduce(
            10,
            src_memory="global",
            src_word_offset=0,
            element_count=len(values_a),
        ),
        dexsim.compare_reduce(
            11,
            src_memory="global",
            src_word_offset=0,
            element_count=len(values_a),
        ),
        dexsim.add_reduce(
            12,
            src_memory="local",
            src_word_offset=0,
            element_count=len(values_b),
        ),
    ])

    for result in trace.command_results:
        print(result.to_dict())
```

兼容的寄存器读取接口仍然保留：

```python
latest_add = session.read_add_reduce()
latest_compare = session.read_compare_reduce()
```

这两个接口只返回对应类型最后一次完成的结果。需要 batch 内每一条结果时，应使用 `trace.command_results`。

Compare-Reduce 实现的是 FP16 最小值归约，并返回最小值的硬件索引。相等值的选择遵循硬件 Reduce tree 的 tie 规则，不应假定等同于 Python `min()` 返回第一个值。

## 10. 各算子接口

所有下面的 builder 都返回 `dexsim.Command`，不会立即运行硬件。

### 10.1 ABS

```python
dexsim.abs(
    command_id,
    src_memory="global",
    src_word_offset=0,
    out_memory="local",
    out_word_offset=0,
    rows=2,
    cols=3,
    group_end=True,
)
```

输出 bit 等于输入 FP16 bit 清除 bit15。输入输出 shape 都是 `rows x cols`。

### 10.2 Add-Reduce

```python
dexsim.add_reduce(
    command_id,
    src_memory="global",
    src_word_offset=0,
    element_count=17,
    group_end=True,
)
```

硬件按照固定 16-lane FP16 加法树及跨 tile 累加顺序执行；结果从 `CommandResult` 取得。

### 10.3 Compare-Reduce

```python
dexsim.compare_reduce(
    command_id,
    src_memory="global",
    src_word_offset=0,
    element_count=17,
    group_end=True,
)
```

返回 FP16 最小值和 element index。

### 10.4 GEMM

```python
dexsim.gemm(
    command_id,
    a_memory="global",
    a_word_offset=0,
    b_memory="local",
    b_word_offset=0,
    out_memory="temp",
    out_word_offset=0,
    n_rows=N,
    m_cols=M,
    k_dim=K,
    group_end=True,
)
```

矩阵布局为 row-major：

- A shape：`N x K`；
- B shape：`K x M`；
- 输出 shape：`N x M`。

### 10.5 GEMV

```python
dexsim.gemv(
    command_id,
    a_memory="global",
    a_word_offset=0,
    x_memory="local",
    x_word_offset=0,
    out_memory="temp",
    out_word_offset=0,
    n_rows=N,
    k_dim=K,
)
```

等价于 `N x K` 矩阵乘 `K x 1` 向量。

### 10.6 DOT

```python
dexsim.dot(
    command_id,
    a_memory="global",
    a_word_offset=0,
    b_memory="local",
    b_word_offset=0,
    out_memory="temp",
    out_word_offset=0,
    element_count=K,
)
```

等价于 `1 x K @ K x 1`，输出一个 FP16 element。

### 10.7 OUTER

```python
dexsim.outer(
    command_id,
    a_memory="global",
    a_word_offset=0,
    b_memory="local",
    b_word_offset=0,
    out_memory="temp",
    out_word_offset=0,
    n_rows=N,
    m_cols=M,
)
```

等价于 `N x 1 @ 1 x M`，输出 `N x M`。

### 10.8 SCALE

```python
dexsim.scale(
    command_id,
    src_memory="global",
    src_word_offset=0,
    out_memory="local",
    out_word_offset=0,
    rows=2,
    cols=3,
    alpha_bits=dexsim.fp16_bits(-0.5),
)
```

`alpha_bits` 必须显式传入 FP16 bit，不接受隐式 Python float。该硬件 subop 是 tensor 乘一个标量，不是两个 tensor 逐元素乘法。

### 10.9 ADD

```python
dexsim.add(
    command_id,
    a_memory="global",
    a_word_offset=0,
    b_memory="local",
    b_word_offset=0,
    out_memory="temp",
    out_word_offset=0,
    rows=2,
    cols=3,
)
```

A、B 和输出都是相同的 `rows x cols` row-major tensor。

### 10.10 SIN / COS / SOFTPLUS

```python
dexsim.sin(
    command_id,
    src_memory="global",
    src_word_offset=0,
    out_memory="local",
    out_word_offset=0,
    rows=2,
    cols=3,
)

dexsim.cos(...)

dexsim.softplus(...)
```

三者参数结构相同，都是逐元素 LUT 算子。

第一次执行 Sin 或 Cos 时，Session 自动将 wheel 中的 `trig_data.hex` 加载到 4 个 Trig SRAM bank；同一 Session 后续 Sin/Cos 不重复加载。

第一次执行 Softplus 时，Session 自动将 `softplus_data.hex` 加载到 2 个 Softplus SRAM bank；同一 Session 后续不重复加载。

首次加载成本记录在 `RunResult.setup_*`；第二次相同类别 LUT 调用的 setup 统计为 0。Trig 和 Softplus 使用彼此独立的懒加载状态。

### 10.11 TRANSPOSE

```python
dexsim.transpose(
    command_id,
    src_memory="global",
    src_word_offset=0,
    out_memory="local",
    out_word_offset=0,
    rows=2,
    cols=3,
)
```

输入为 `rows x cols`，输出为 `cols x rows`，均为 row-major。

### 10.12 ASSEMBLE

```python
dexsim.assemble(
    command_id,
    src_memory="global",
    src_word_offset=0,
    out_memory="temp",
    out_word_offset=0,
    rows=2,
    cols=3,
    offset_row=1,
    offset_col=2,
)
```

当前 command 能编码源 shape 和两个 offset。RTL 由此推导目标 shape：

```text
dst_rows = rows + offset_row
dst_cols = cols + offset_col
```

上述例子的目标 shape 为 `3 x 5`。执行前可先在目标区域写入初值；硬件只覆盖从 `[offset_row, offset_col]` 开始的源矩阵区域，目标区域内其余元素保持原值。

该版本不承诺比上述推导结果更大的任意目标 shape，因为 command 中没有独立字段编码额外的目标行列数。

## 11. SRAM 重叠规则

当前 SDK 对会写输出的算子执行 word 粒度重叠检查：

- ABS、SCALE、LUT、Transpose、Assemble：源与输出不能重叠；
- ADD：A/output 和 B/output 均不能重叠；
- GEMM/GEMV/DOT/OUTER：输入与输出不能重叠；
- 两个只读输入彼此可以重叠；
- Reduce 没有 SRAM 输出。

即使两个 tensor 只在同一个 128-bit word 的不同 FP16 lane 中占用空间，command 硬件也是 word 基址访问，因此 SDK 仍按重叠处理。需要 in-place 优化时，应先做独立 RTL 验证，再扩展该安全策略。

## 12. 错误处理和资源释放

常见异常：

- 参数类型、维度、地址、SRAM 容量或重叠错误：`TypeError` / `ValueError`；
- native runtime、timeout、illegal command、完成元数据不一致或 LUT 数据错误：`dexsim.DexSimError`；
- wheel 缺少 native shared library：`ImportError`。

推荐始终使用 context manager：

```python
with dexsim.Session() as session:
    ...
```

也可以手动调用：

```python
session = dexsim.Session()
try:
    ...
finally:
    session.close()
```

关闭后的 Session 不能再次使用。

## 13. 能力查询

```python
import json
import dexsim

print(json.dumps(dexsim.Session.capabilities(), indent=2))
```

关键字段包括：

- `runtime_enabled_cores: [0]`；
- `primitive_operators`：11 个硬件 primitive；
- `derived_operators: ["gemv", "dot", "outer"]`；
- `operator_core: 0`；
- `bit_exact_tensor_io: true`；
- `per_command_results: true`。

## 14. 完整验证命令

### 14.1 从隔离安装目录运行全部 Python 测试

```sh
cd ~/Workspace/DexMPC_post_to/DexMPC_sim

PYTHONPATH=/tmp/dexsim-sdk-0.2.0 \
  ~/miniforge3/bin/conda run -n dexsim_verilator \
  python -m unittest discover -s tests/python -p 'test_*.py' -v
```

测试包括：

- 全部 11 个 primitive 的固定 96-bit command golden vector；
- GEMV/DOT/OUTER 与等价 GEMM 编码一致性；
- FP16 bit I/O；
- 全部 primitive 和派生算子的硬件输出；
- FP16 逐步舍入 reference；
- Add/Compare Reduce tree 及一个 batch 内多条结果；
- Trig/Softplus LUT bit-level reference 和懒加载；
- DataLayout；
- 参数、越界、重叠、timeout 和 illegal command；
- 原 M2 GEMM/Softplus/Add-Reduce/persistence 回归。

建议连续运行两次：

```sh
for run in 1 2; do
  PYTHONPATH=/tmp/dexsim-sdk-0.2.0 \
    ~/miniforge3/bin/conda run -n dexsim_verilator \
    python -m unittest discover -s tests/python -p 'test_*.py' -v
done
```

### 14.2 生成全算子覆盖 JSON 和 256 命令持久性结果

```sh
PYTHONPATH=/tmp/dexsim-sdk-0.2.0 \
  ~/miniforge3/bin/conda run -n dexsim_verilator \
  python tools/run_sdk_operator_matrix.py \
  --persistence-commands 256 \
  --output /tmp/dexsim_operator_coverage.json
```

JSON 顶层 `passed` 应为 `true`。

### 14.3 运行原 M2 smoke

```sh
PYTHONPATH=/tmp/dexsim-sdk-0.2.0 \
  ~/miniforge3/bin/conda run -n dexsim_verilator \
  python tools/run_sdk_smoke.py \
  --persistence-runs 100 \
  --output /tmp/dexsim_sdk_smoke.json
```

### 14.4 检查 native 动态依赖

```sh
ldd /tmp/dexsim-sdk-0.2.0/dexsim/_native/libdexsim_runtime.so
```

### 14.5 记录 wheel 哈希

pip 的临时 wheel 可能被自动清理。如需归档 wheel，可直接调用 PEP 517 backend：

```sh
mkdir -p /tmp/dexsim-wheel-0.2.0

~/miniforge3/bin/conda run -n dexsim_verilator \
  python -c 'import sys; sys.path.insert(0, "build_backend"); import dexsim_build_backend as b; print(b.build_wheel("/tmp/dexsim-wheel-0.2.0"))'

sha256sum /tmp/dexsim-wheel-0.2.0/dexmpc_sim-0.2.0-py3-none-linux_x86_64.whl
```

## 15. 与后续 compiler/MPC 集成的建议

该 SDK 是硬件 primitive 层，不负责把高层 MPC 算法自动拆成命令。后续联合开发建议保持以下分层：

```text
DexMPC_Algorithm / MPC idea software
        |
        | 产生明确 shape、FP16 tensor 和算子图
        v
compiler / SRAM planner / command scheduler
        |
        | 调用本手册中的 builder 和 Session
        v
dexmpc-sim Python SDK
        |
        v
C ABI -> C++ persistent Session -> D2D TopChip Verilator model
```

高层集成代码应：

1. 在进入硬件边界前明确量化为 FP16；
2. 由 compiler/planner 统一分配 Global/Local/Temp 的 word-aligned command 区域；
3. 使用 bit I/O 保存量化常量的精确编码；
4. 用 `command_results` 关联 Reduce 结果；
5. 分开统计一次性 `setup_*` 和稳态 `cycles/read_bytes/write_bytes`；
6. 在算法回退或硬件不支持时由上层显式选择软件路径，不能通过 raw command 假装支持。
