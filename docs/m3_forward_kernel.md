# M3 explicit-model forward kernel

This document describes the fixed M3 lowering implemented by
`dexsim.kernels.DexMPCForwardKernel`.  It is an audited first kernel for the
DexMPC explicit dynamics model, not a general graph compiler or SRAM allocator.

## Hardware subgraph

For one MPC stage, the kernel evaluates:

```text
b_r       = robot_stiff @ u
b         = host_concat(object_force, b_r)
x         = Q_inv @ b
t         = jac @ x
z         = -sigma * (t + phi) - 0.1 * sigma / h * t
s         = scale(softplus(scale(z, 100)), 0.01)
v         = scale(x + Q_inv @ (jac.T @ s), 1 / h)
```

The hardware portion uses 14 commands per stage:

- 5 GEMV commands;
- 3 elementwise ADD commands;
- 5 SCALE commands;
- 1 Softplus LUT command.

`Q_inv` is computed by the caller in host FP64 and is quantized once to FP16
when the kernel is constructed.  `robot_stiff`, `jac`, `jac.T` and `phi` are
also quantized and preloaded once.  The same `dexsim.Session` is reused across
all stages.

## Deliberate host boundary

The current Assemble primitive cannot express the packed one-dimensional
`concat(object_force, b_r)` without adding padding.  M3 therefore reads the
FP16 `b_r`, performs a bit-preserving host concat, and writes the FP16 `b` back
to Local SRAM.  This barrier and its D2D cost are recorded in every stage
trace.  State and quaternion integration are intentionally owned by
`DexMPC_Algorithm`, because they were not selected as part of this first
hardware kernel.

## Use

```python
import numpy as np
import dexsim
from dexsim.kernels import DexMPCForwardKernel

with dexsim.Session(transport="d2d", cores=[0]) as session:
    kernel = DexMPCForwardKernel(
        session,
        object_force=obj_mass * gravity,
        q_inv=np.linalg.inv(Q.astype(np.float64)),
        robot_stiff=robot_stiff,
        jac=jac,
        phi=phi,
        h=0.1,
        sigma=0.5,
    )
    stage = kernel.run_stage(u, capture_intermediates=True)
    velocity = stage.velocity
    trace = stage.trace
```

`run_stage()` returns the velocity both as Python floats and raw FP16 bits.
When `capture_intermediates=True`, all intermediate tensors are read back and
checked bit-for-bit against the M3 reference model.  A mismatch raises
`DexSimError`; there is no silent software fallback.

## FP16 semantics

The linear-algebra and elementwise arithmetic units instantiate Synopsys DW
models with `IEEE_COMPLIANCE=0`.  Consequently, FP16 exponent-zero subnormal
operands and underflowed arithmetic results are flushed to signed zero.  The
M3 reference model reproduces this behavior after every add, multiply and MAC.
Softplus is reproduced from the exact packaged LUT data.

The MAC-array commands have one additional observable detail. ADD streams both
operands through a cleared accumulator, while GEMM/GEMV accumulates the dot
product; both paths then drain the pipeline with positive zero. Under
round-to-nearest this canonicalizes a final zero result to `+0`, including an
intermediate negative zero. Command-level references therefore model the
complete accumulator pipeline rather than only the arithmetic inner loop.

This FTZ rule is important for the airplane fixture because several command
components are around `1e-6` to `1e-5`.  A normal host FP16 reference that
preserves subnormal arithmetic is not bit-accurate for this RTL.

## SRAM layout

`build_forward_sram_layout()` creates a deterministic word-aligned lifetime
layout.  For the Allegro airplane dimensions (`n_qvel=22`, `n_cmd=16`,
`contact_rows=60`), static tensors occupy 431 of 2048 Global words and scratch
tensors occupy 86 of 512 Local words.  Temp SRAM is not needed.  The complete
address map is included in the generated M3 JSON report.

## Validation

Pure reference/layout tests:

```sh
PYTHONPATH=/path/to/installed/dexsim \
  python -m unittest tests/python/test_forward_kernel.py -v
```

The formal 4-stage validation is driven from `DexMPC_Algorithm`:

```sh
PYTHONPATH=/path/to/installed/dexsim \
  python tools/run_first_dexsim_slice.py \
    --fixture tests/fixtures/airplane_seed0_first_linesearch.npz \
    --report out/first_slice.json
```
