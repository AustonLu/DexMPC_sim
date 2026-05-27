# Trig LUT 规格说明

## 1. 概述

本模块输入为 FP16 角度 `x`，输出为 FP16 的 `sin(x)` 和 `cos(x)`。

当前设计的核心目标是：
- 只保存一份数学意义上的 `sin(θ)` LUT，`θ ∈ [0, π/2]`
- `cos(x)` 通过角度折叠复用同一份 `sin` LUT
- 为了在同一个请求里并行得到 `sin` 和 `cos`，物理上放置两份完全相同的 `sin LUT` 副本
- 不使用除法器做模 `2π` 归约，而是通过循环减 `2π` 把输入幅值归约到 `[0, 2π]`


## 2. SRAM 组织

物理上使用 4 个 `128 x 16` SRAM：

- `SRAM0` -> `sinEven`
- `SRAM1` -> `sinOdd`
- `SRAM2` -> `cosEven`
- `SRAM3` -> `cosOdd`

注意：
- `sinEven + sinOdd` 组成副本 A
- `cosEven + cosOdd` 组成副本 B
- 副本 A 和副本 B 的内容完全相同，保存的都是 `sin(θ)` LUT
- 并不存在单独的 `cos LUT`


## 3. `trig_data.hex` 的装载顺序

`trig_data.hex` 按如下顺序写入：

1. 第 `0 ~ 127` 行写入 `sinEven`
2. 第 `128 ~ 255` 行写入 `sinOdd`
3. 第 `256 ~ 383` 行写入 `cosEven`
4. 第 `384 ~ 511` 行写入 `cosOdd`

其中：
- 第 `0 ~ 255` 行和第 `256 ~ 511` 行是两份完全相同的数据
- 即 `cosEven == sinEven`
- 即 `cosOdd == sinOdd`


## 4. FP16 常数

使用以下 FP16 常数：

| 名称 | FP16 hex | 含义 |
|---|---|---|
| `PI_HALF` | `0x3E48` | `π/2 ≈ 1.5703` |
| `PI` | `0x4248` | `π ≈ 3.1406` |
| `PI_3H` | `0x44B6` | `3π/2 ≈ 4.7109` |
| `PI_2` | `0x4648` | `2π ≈ 6.2813` |


## 5. 输入预处理

对输入 FP16 `x_bits`：

```text
input_sign = x_bits[15]
abs_bits   = x_bits & 0x7FFF
abs_x      = FP16(abs_bits)
```

后续的角度折叠只对 `abs_x` 进行，`sin` 的最终符号再结合 `input_sign` 决定。


## 6. 先做幅值归约到 `[0, 2π]`

为了支持超出 `[-2π, 2π]` 的输入，先把 `abs_x` 归约到 `[0, 2π]`。

设计不使用除法器，而是采用循环减法：

```text
reduced_abs = abs_x
while reduced_abs > FP16(2π):
    reduced_abs = reduced_abs - FP16(2π)
```

实现约束：
- 这里只对非负幅值做比较和减法
- 不需要完整的有符号 FP16 加法器
- 原始符号 `input_sign` 单独锁存，最后再参与 `sin` 的符号修正


## 7. 象限判断

在 `reduced_abs ∈ [0, 2π]` 后，按照如下规则分象限：

```text
if   reduced_abs <= PI_HALF: Q = 1
elif reduced_abs <= PI:      Q = 2
elif reduced_abs <= PI_3H:   Q = 3
else:                        Q = 4
```


## 8. 查询角折叠

所有 LUT 最终都只查询：

```text
sin(theta), theta ∈ [0, π/2]
```

### 8.1 `sin(x)` 的查询角

| 象限 | `reduced_abs` 范围 | `theta_sin` | 最终符号 |
|---|---|---|---|
| Q1 | `[0, π/2]` | `reduced_abs` | `+` |
| Q2 | `(π/2, π]` | `PI - reduced_abs` | `+` |
| Q3 | `(π, 3π/2]` | `reduced_abs - PI` | `-` |
| Q4 | `(3π/2, 2π]` | `PI_2 - reduced_abs` | `-` |

最终符号：

```text
sin_negate = (Q == 3 || Q == 4) XOR input_sign
```

### 8.2 `cos(x)` 的查询角

利用：

```text
cos(x) = sin(π/2 - x)
```

折叠后：

| 象限 | `reduced_abs` 范围 | `theta_cos` | 最终符号 |
|---|---|---|---|
| Q1 | `[0, π/2]` | `PI_HALF - reduced_abs` | `+` |
| Q2 | `(π/2, π]` | `reduced_abs - PI_HALF` | `-` |
| Q3 | `(π, 3π/2]` | `PI_3H - reduced_abs` | `-` |
| Q4 | `(3π/2, 2π]` | `reduced_abs - PI_3H` | `+` |

最终符号：

```text
cos_negate = (Q == 2 || Q == 3)
```


## 9. LUT 地址提取

对折叠后的查询角：

```text
addr = (theta_bits & 0x7FFF) >> 6
```

由于 `theta ∈ [0, π/2]`，所以：

```text
addr ∈ [0, 249]
```

地址拆分方式：

```text
addr[7]   : bank select
addr[6:0] : row address
```

访问规则：

```text
sin path:
  bank=0 -> sinEven
  bank=1 -> sinOdd

cos path:
  bank=0 -> cosEven
  bank=1 -> cosOdd
```


## 10. 时序流程

模块对外接口包含：
- `start`
- `busy`
- `done`
- `sin`
- `cos`

时序上按如下阶段工作：

### Step 1：接收输入

在 `start` 有效时锁存：

```text
input_sign
abs_x
```

### Step 2：幅值归约

若 `abs_x > 2π`，则进入归约状态，每拍执行一次：

```text
abs_x := abs_x - 2π
```

直到 `abs_x <= 2π`。

### Step 3：计算两路查询地址和符号

根据归约后的 `abs_x`：
- 判断象限
- 计算 `theta_sin`
- 计算 `theta_cos`
- 计算 `sin_negate`
- 计算 `cos_negate`
- 计算 `sin` / `cos` 两路的 bank 和 row

### Step 4：发起 SRAM 读请求

同一拍并行访问两份 `sin LUT` 副本：

```text
sin LUT copy A -> sinEven/sinOdd
sin LUT copy B -> cosEven/cosOdd
```

### Step 5：下一拍接收 LUT 数据

SRAM 为同步读：
- 写入地址后的下一拍返回数据

### Step 6：符号修正并输出

```text
sin = sin_negate ? negate(lut_sin) : lut_sin
cos = cos_negate ? negate(lut_cos) : lut_cos
```

同拍：
- `sin` / `cos` 有效
- `done` 拉高 1 个周期


## 11. 设计总结

当前 `TrigLut` 的设计意图是：

1. 用同一份 `sin(θ)` LUT 数据同时支持 `sin` 和 `cos`
2. 通过两份完全相同的物理副本支持并行读取
3. 通过“循环减 `2π`”而不是除法器完成角度归约
4. 归约后再做象限折叠和符号修正
5. 最终输入、查表值、输出值全部保持 FP16
