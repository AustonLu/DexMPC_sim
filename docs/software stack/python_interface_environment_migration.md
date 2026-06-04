# DexMPC Python 接口层环境迁移指南

本文档用于把 DexMPC Python 接口层迁移到一套全新的开发环境。目标是让新环境能重新生成 Verilator full-chip simulator、构建 Python native binding，并运行 Python 接口层测试。

## 1. 环境组成

Python 接口层依赖以下组件：

| 类别 | 要求 |
| --- | --- |
| OS | Linux x86_64，当前验证环境为 Ubuntu 类系统 |
| Python | Python 3.x，当前验证为 Anaconda Python 3.13 |
| C++ 编译器 | 支持 C++17 的 `g++` |
| Make | GNU Make |
| Verilator | 需要提供 `share/verilator/include/verilated.cpp` |
| Git | 用于代码同步 |
| Python 包 | 当前 Python 测试只使用标准库，不依赖 pytest/numpy |

## 2. 推荐目录结构

推荐把 Verilator 和仓库分开放置：

```text
~/dex_cycle_model/
  tools/
    verilator/
      bin/verilator
      share/verilator/include/verilated.cpp
  test_mpc/
    software_stack/
    verification/
    docs/
```

如果 Verilator 安装在其他路径，也可以使用环境变量或命令行参数指定。

## 3. 必要环境变量

Python binding 构建脚本需要 Verilator 的 `share/verilator` 目录：

```bash
export VERILATOR_ROOT=/path/to/verilator/share/verilator
```

如果使用当前工程本地安装的 Verilator，示例为：

```bash
export VERILATOR_ROOT=/home/ljj/dex_cycle_model/tools/verilator/share/verilator
export PATH=/home/ljj/dex_cycle_model/tools/verilator/bin:$PATH
```

运行 Python 包时需要设置：

```bash
export PYTHONPATH=$PWD/software_stack/python
```

## 4. libstdc++ 版本要求

native module 由系统 `g++` 构建，因此运行时 Python 进程需要能加载包含所需 `GLIBCXX` 符号的 `libstdc++.so.6`。

当前机器上的问题是：

- Anaconda 自带 `libstdc++.so.6.0.29`。
- 系统 `g++` 构建出的 `.so` 需要 `GLIBCXX_3.4.30`。

如果新环境也遇到类似错误：

```text
ImportError: libstdc++.so.6: version `GLIBCXX_3.4.30' not found
```

可以先用系统 libstdc++ 运行：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport d2d
```

更干净的长期方案是：

- 使用系统 Python 或与系统编译器匹配的虚拟环境。
- 或升级 Conda 环境中的 `libstdcxx-ng`。
- 或统一使用 Conda 编译器和 Conda 运行时重建 native module。

## 5. 生成 Verilator full-chip simulator

Python native binding 不是直接调用 Verilator 命令，而是链接已经生成的 full-chip Verilator C++ 模型归档。

当前构建脚本期望存在以下目录和文件：

```text
build/verilator/full_chip/topchip_d2d_mixed_tb/VTopChipTopD2dHarness.mk
build/verilator/full_chip/topchip_d2d_mixed_tb/VTopChipTopD2dHarness__ALL.a

build/verilator/full_chip/topchiptop_legacy_spi_tb/VTopChipTop.mk
build/verilator/full_chip/topchiptop_legacy_spi_tb/VTopChipTop__ALL.a
```

如果新环境没有这些文件，需要先生成 D2D model：

```bash
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTopD2dHarness \
  -f verification/verilator/filelists/topchip_top_d2d_harness.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_d2d_mixed.cpp \
  --Mdir build/verilator/full_chip/topchip_d2d_mixed_tb \
  -CFLAGS "-I$PWD/verification/verilator/cpp/common"
```

再生成 SPI model：

```bash
env CCACHE_DISABLE=1 verilator -sv --cc --top-module TopChipTop \
  -f verification/verilator/filelists/topchip_top.f \
  --exe verification/verilator/cpp/tests/full_chip/tb_topchip_spi_mixed.cpp \
  --Mdir build/verilator/full_chip/topchiptop_legacy_spi_tb \
  -CFLAGS "-I$PWD/verification/verilator/cpp/common"
```

## 6. 构建 Python native binding

设置 `VERILATOR_ROOT` 后，构建 D2D 和 SPI native module：

```bash
export VERILATOR_ROOT=/path/to/verilator/share/verilator
python3 software_stack/python/build_python_bindings.py --transport all
```

也可以不用环境变量，直接传参：

```bash
python3 software_stack/python/build_python_bindings.py \
  --verilator-root /path/to/verilator/share/verilator \
  --transport all
```

构建脚本会：

1. 重新用 `-fPIC` 编译 Verilator archive。
2. 链接 CPython extension。
3. 生成：

```text
software_stack/python/dexmpc/_native_d2d*.so
software_stack/python/dexmpc/_native_spi*.so
```

这些 `.so` 是构建产物，不建议提交到 Git。

## 7. 运行 Python 测试

D2D 全量测试：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport d2d
```

SPI pad-level simulation 很慢，建议先跑 8 个 mixed case：

```bash
LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
PYTHONPATH=software_stack/python \
python3 software_stack/tests/python/test_python_interface_layer.py --transport spi --mixed-case-limit 8
```

如果新环境的 libstdc++ 没有版本冲突，可以去掉 `LD_PRELOAD`。

## 8. 迁移检查清单

迁移到新环境时逐项确认：

- `git clone` 后源码完整。
- `verilator --version` 可执行。
- `$VERILATOR_ROOT/include/verilated.cpp` 存在。
- `g++ --version` 支持 C++17。
- `python3 -V` 是目标 Python。
- `python3 -c "import sysconfig; print(sysconfig.get_config_var('INCLUDEPY'))"` 能找到 Python header。
- Verilator D2D/SPI model 的 `.mk` 和 `__ALL.a` 文件已经生成。
- `python3 software_stack/python/build_python_bindings.py --transport all` 成功。
- `PYTHONPATH=software_stack/python python3 -c "import dexmpc"` 成功。
- D2D Python test 通过。
- SPI limited Python test 通过。

## 9. 常见问题

### 找不到 Verilator header

现象：

```text
Set VERILATOR_ROOT or pass --verilator-root
```

处理：

```bash
export VERILATOR_ROOT=/path/to/verilator/share/verilator
```

### 找不到 Python.h

确认当前 Python 环境安装了开发头文件。系统 Python 通常需要安装类似 `python3-dev` 的包；Conda Python 通常自带 header。

### native module 导入失败

先检查是否存在 `.so`：

```bash
ls software_stack/python/dexmpc/_native_*.so
```

再检查 libstdc++：

```bash
strings /usr/lib/x86_64-linux-gnu/libstdc++.so.6 | grep GLIBCXX_3.4.30
```

必要时使用 `LD_PRELOAD` 或调整 Python/编译器环境。

### SPI 测试很慢

这是预期现象。SPI 使用 pad-level transport，仿真速度明显慢于 D2D。迁移阶段建议先使用：

```bash
--mixed-case-limit 8
```
