#!/usr/bin/env python3
"""Build local DexMPC Python native bindings without external Python packages."""

from __future__ import annotations

import argparse
import os
import shlex
import subprocess
import sys
import sysconfig
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PYTHON_ROOT = ROOT / "software_stack" / "python"
CPP_SOURCE = PYTHON_ROOT / "cpp" / "dexmpc_python_binding.cpp"
PACKAGE_DIR = PYTHON_ROOT / "dexmpc"


def run(cmd: list[str]) -> None:
    print("+", " ".join(shlex.quote(part) for part in cmd))
    subprocess.run(cmd, cwd=ROOT, check=True)


def python_include() -> str:
    include = sysconfig.get_config_var("INCLUDEPY")
    if not include:
        raise RuntimeError("Python INCLUDEPY is unavailable")
    return include


def extension_suffix() -> str:
    suffix = sysconfig.get_config_var("EXT_SUFFIX")
    if not suffix:
        raise RuntimeError("Python EXT_SUFFIX is unavailable")
    return suffix


def resolve_verilator_root(value: str | None) -> Path:
    root_text = value or os.environ.get("VERILATOR_ROOT")
    if not root_text:
        raise RuntimeError("Set VERILATOR_ROOT or pass --verilator-root to locate Verilator headers")
    root = Path(root_text).expanduser().resolve()
    if not (root / "include" / "verilated.cpp").exists():
        raise RuntimeError(f"invalid Verilator root: {root}")
    return root


def rebuild_pic_archive(verilator_dir: Path, makefile: str, archive: str, jobs: int) -> None:
    run([
        "make",
        "-B",
        f"-j{jobs}",
        "-C",
        str(verilator_dir),
        "-f",
        makefile,
        "OBJCACHE=",
        "CXXFLAGS=-fPIC",
        archive,
    ])


def build_one(
    name: str,
    transport_macro: str,
    verilator_dir: Path,
    makefile: str,
    archive: str,
    verilator_root: Path,
    jobs: int,
) -> None:
    rebuild_pic_archive(verilator_dir, makefile, archive, jobs)
    output = PACKAGE_DIR / f"_{name}{extension_suffix()}"
    cmd = [
        "g++",
        "-std=c++17",
        "-shared",
        "-fPIC",
        f"-DDEXMPC_PY_MODULE_NAME=_{name}",
        "-DDEXMPC_ENABLE_TOPCHIP_SIM_BACKEND",
        f"-D{transport_macro}",
        f"-I{python_include()}",
        "-Isoftware_stack/include",
        "-Iverification/verilator/cpp/common",
        f"-I{verilator_dir}",
        f"-I{verilator_root / 'include'}",
        f"-I{verilator_root / 'include' / 'vltstd'}",
        str(CPP_SOURCE),
        str(verilator_dir / archive),
        str(verilator_root / "include" / "verilated.cpp"),
        str(verilator_root / "include" / "verilated_threads.cpp"),
        "-pthread",
        "-o",
        str(output),
    ]
    run(cmd)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--transport", choices=("d2d", "spi", "all"), default="all")
    parser.add_argument("--verilator-root", help="Path to Verilator share/verilator directory")
    parser.add_argument("--jobs", type=int, default=4, help="Parallel make jobs for PIC archive rebuild")
    args = parser.parse_args()

    if args.jobs <= 0:
        raise RuntimeError("--jobs must be positive")
    verilator_root = resolve_verilator_root(args.verilator_root)

    PACKAGE_DIR.mkdir(parents=True, exist_ok=True)
    if args.transport in ("d2d", "all"):
        build_one(
            "native_d2d",
            "DEX_TOPCHIP_TRANSPORT_D2D",
            ROOT / "build" / "verilator" / "full_chip" / "topchip_d2d_mixed_tb",
            "VTopChipTopD2dHarness.mk",
            "VTopChipTopD2dHarness__ALL.a",
            verilator_root,
            args.jobs,
        )
    if args.transport in ("spi", "all"):
        build_one(
            "native_spi",
            "DEX_TOPCHIP_TRANSPORT_SPI",
            ROOT / "build" / "verilator" / "full_chip" / "topchiptop_legacy_spi_tb",
            "VTopChipTop.mk",
            "VTopChipTop__ALL.a",
            verilator_root,
            args.jobs,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
