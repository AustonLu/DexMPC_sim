# Softplus LUT 查找规格说明

## 1. 概述

本模块对任意 FP16 输入 `x` 计算 softplus 函数：

$$f(x) = \ln(1 + e^x)$$

采用分段策略：在 $(-3.5,\ 3.5)$ 区间内通过预计算 LUT 查表得到结果，区间外使用解析近似。

---

## 2. 分段判断逻辑

对输入 FP16 值 `x`，按以下四个区间分别处理：

```
                -3.5          0          3.5
─────────────────┼────────────┼────────────┼─────────────→ x
   输出 = 0      │  查LUT后   │   直接查   │  输出 = x
  （截断为0）    │   做修正   │    LUT     │  （线性近似）
```

| 区间 | 条件 | 输出 |
|---|---|---|
| 极负区 | $x < -3.5$ | $y = 0$ |
| 负区 | $-3.5 \leq x < 0$ | $y = \text{LUT}[\text{addr}(\|x\|)]\ -\ \|x\|$ |
| 正区 | $0 \leq x \leq 3.5$ | $y = \text{LUT}[\text{addr}(x)]$ |
| 极正区 | $x > 3.5$ | $y = x$ |

> **负区公式的数学依据：**
> $$\text{softplus}(x) = \text{softplus}(-x) + x = \text{softplus}(|x|) - |x| \quad (x < 0)$$

---

## 3. LUT 地址计算

### 3.1 FP16 格式回顾

```
 Bit 15   Bit 14:10   Bit 9:0
┌──────┬─────────────┬──────────────┐
│ sign │  exp (5b)   │ mantissa(10b)│
└──────┴─────────────┴──────────────┘
```

### 3.2 地址提取

取 FP16 **正数表示**（即符号位为 0 的部分）的高 10 位：

```
addr[9:0] = FP16_bits[14:5]
          = (FP16_bits & 0x7FFF) >> 5
```

对正数输入直接提取；对负数输入，先取绝对值（清除符号位），再提取：

```
|x| 的地址 = (FP16_bits & 0x7FFF) >> 5    // 符号位清零，右移5位
```

### 3.3 阈值对应地址

| 值 | FP16 十六进制 | FP16 二进制 | 15-bit 整数 | LUT 地址 |
|---|---|---|---|---|
| 3.5 | `0x4300` | `0100 0011 0000 0000` | 17152 | **536** |
| -3.5 | `0xC300` | `1100 0011 0000 0000` | — | **536**（取绝对值后同） |

**判断规则（硬件实现）：**

```
positive_bits = FP16_bits & 0x7FFF   // 去掉符号位
addr          = positive_bits >> 5   // 右移5位，得10-bit地址

if   positive_bits == 0:             // x == ±0
    region = POS
elif addr > 536:                     // |x| > 3.5
    region = (sign == 0) ? FAR_POS : FAR_NEG
elif sign == 0:
    region = POS                     // 0 ≤ x ≤ 3.5
else:
    region = NEG                     // -3.5 ≤ x < 0
```

---

## 4. LUT 组织方式

### 4.1 存储结构

- **SRAM 配置**：2 块 256×32 SRAM，合计 1024 个 FP16 条目
- **寻址**：10-bit 地址（`addr[9:0]`）
  - `addr[9]`：选择 SRAM bank（0 = SRAM1，1 = SRAM2）
  - `addr[8:1]`：SRAM 行地址（8-bit）
  - `addr[0]`：选择 32-bit word 中的低/高 16 位

```
  addr[9]  addr[8:1]  addr[0]
    │         │          │
    ▼         ▼          ▼
 bank sel   row(0~255)  word sel
                        0 → bits[15:0]
                        1 → bits[31:16]
```

### 4.2 条目内容

每个条目存储其 bucket 中点对应的 softplus FP16 值：

```
Bucket addr 的覆盖范围（FP16 正数 15-bit 值）：
  lo_bits  = addr × 32
  hi_bits  = (addr + 1) × 32 − 1
  mid_bits = (lo_bits + hi_bits) / 2

LUT[addr] = FP16( softplus( fp16(mid_bits) ) )
```

### 4.3 有效地址范围

| 地址范围 | 对应 x 范围 | 状态 |
|---|---|---|
| 0 ~ 536 | $0 \leq x \leq 3.5$ | 有效（已写入 softplus 值） |
| 537 ~ 1023 | $x > 3.5$ | 未使用（全零，硬件不会访问） |

---

## 5. 完整计算步骤

```
输入：FP16 x

Step 1: 提取字段
   sign         = FP16_bits[15]
   positive_bits = FP16_bits & 0x7FFF
   addr         = positive_bits >> 5

Step 2: 区间判断
   if addr > 536:
       if sign == 0:  输出 x              // 极正区：y = x
       else:          输出 0              // 极负区：y = 0
       结束

Step 3: 查 LUT
   lut_val = LUT[addr]                   // 以 addr 查表，得 FP16 值

Step 4: 计算输出
   if sign == 0:
       输出 lut_val                      // 正区：y = LUT[addr(x)]
   else:
       abs_x  = FP16(positive_bits)      // 重建 |x|
       输出 lut_val - abs_x              // 负区：y = LUT[addr(|x|)] - |x|
```

---

## 6. 误差说明

| 区间 | 最大绝对误差 | 最大相对误差 | 说明 |
|---|---|---|---|
| $(0,\ 3.5]$ | $3.08 \times 10^{-2}$ | **0.95%** | LUT bucket 量化误差，worst at x≈3.19 |
| $[-3.5,\ 0)$ | $3.08 \times 10^{-2}$ | **0.95%** | 与正区对称，误差量级相同 |
| $x > 3.5$ | $\ln(1+e^{-3.5}) \approx 2.98\times10^{-2}$ | 0.84% | bypass 误差 $= \ln(1+e^{-x}) \leq \ln(1+e^{-3.5})$ |
| $x < -3.5$ | $\text{softplus}(x) \approx e^x \leq e^{-3.5} \approx 0.03$ | — | 截断为 0 的绝对误差 |

**综合最大误差**：约 **0.95%**（相对误差）

---

## 7. 硬件实现要点

| 操作 | 实现方式 | 代价 |
|---|---|---|
| 符号位提取 `sign` | `FP16_bits[15]` | 0 门 |
| 绝对值 `positive_bits` | `FP16_bits & 0x7FFF`（清除 bit15） | 0 门 |
| 地址提取 `addr` | `positive_bits >> 5`（右移5位） | 0 门（连线） |
| 阈值判断 `addr > 536` | 10-bit 无符号比较器 | ~10 门 |
| SRAM 查表 | 标准双端口 SRAM 读 | 1 周期 |
| 负区修正 `lut_val - abs_x` | FP16 减法器 | ~500 门 |
| 输出选择 | 4:1 MUX（16-bit） | ~64 门 |
