import base64
import csv
import hashlib
import os
import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path


NAME = "dexmpc-sim"
NORMALIZED_NAME = "dexmpc_sim"
VERSION = "0.4.2"
DIST_INFO = f"{NORMALIZED_NAME}-{VERSION}.dist-info"
WHEEL_NAME = f"{NORMALIZED_NAME}-{VERSION}-py3-none-linux_x86_64.whl"


def get_requires_for_build_wheel(config_settings=None):
    return []


def _metadata_text():
    return (
        "Metadata-Version: 2.3\n"
        f"Name: {NAME}\n"
        f"Version: {VERSION}\n"
        "Summary: Address-free FP16 Operator SDK and cycle-accurate runtime for DexMPC TopChip\n"
        "Requires-Python: >=3.9\n"
    )


def _wheel_text():
    return (
        "Wheel-Version: 1.0\n"
        "Generator: dexsim_build_backend\n"
        "Root-Is-Purelib: false\n"
        "Tag: py3-none-linux_x86_64\n"
    )


def prepare_metadata_for_build_wheel(metadata_directory, config_settings=None):
    destination = Path(metadata_directory) / DIST_INFO
    destination.mkdir(parents=True, exist_ok=True)
    (destination / "METADATA").write_text(_metadata_text(), encoding="utf-8")
    (destination / "WHEEL").write_text(_wheel_text(), encoding="utf-8")
    return DIST_INFO


def _record_hash(path):
    digest = hashlib.sha256(path.read_bytes()).digest()
    encoded = base64.urlsafe_b64encode(digest).rstrip(b"=").decode("ascii")
    return f"sha256={encoded}"


def _write_record(stage):
    record_path = stage / DIST_INFO / "RECORD"
    rows = []
    for path in sorted(stage.rglob("*")):
        if path.is_file() and path != record_path:
            relative = path.relative_to(stage).as_posix()
            rows.append((relative, _record_hash(path), str(path.stat().st_size)))
    rows.append((f"{DIST_INFO}/RECORD", "", ""))
    with record_path.open("w", newline="", encoding="utf-8") as output:
        csv.writer(output, lineterminator="\n").writerows(rows)


def build_wheel(wheel_directory, config_settings=None, metadata_directory=None):
    source_root = Path(__file__).resolve().parents[1]
    wheel_directory = Path(wheel_directory)
    wheel_directory.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="dexsim-wheel-") as temporary:
        temporary = Path(temporary)
        build_dir = temporary / "build"
        stage = temporary / "stage"
        package = stage / "dexsim"
        shutil.copytree(source_root / "python" / "dexsim", package)
        data_dir = package / "_data"
        data_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(
            source_root / "rtl" / "chisel" / "top_connect" / "src" / "lut" / "tools"
            / "softplus_data.hex",
            data_dir / "softplus_data.hex",
        )
        shutil.copy2(
            source_root / "rtl" / "chisel" / "top_connect" / "src" / "lut" / "tools"
            / "trig_data.hex",
            data_dir / "trig_data.hex",
        )

        subprocess.run(
            ["cmake", "-S", str(source_root), "-B", str(build_dir), "-DCMAKE_BUILD_TYPE=Release"],
            check=True,
            cwd=source_root,
        )
        subprocess.run(
            ["cmake", "--build", str(build_dir), "--parallel", os.environ.get("DEXSIM_BUILD_JOBS", "8")],
            check=True,
            cwd=source_root,
        )

        native_dir = package / "_native"
        native_dir.mkdir(parents=True, exist_ok=True)
        shutil.copy2(build_dir / "lib" / "libdexsim_runtime.so", native_dir)

        dist_info = stage / DIST_INFO
        dist_info.mkdir(parents=True, exist_ok=True)
        (dist_info / "METADATA").write_text(_metadata_text(), encoding="utf-8")
        (dist_info / "WHEEL").write_text(_wheel_text(), encoding="utf-8")
        _write_record(stage)

        wheel_path = wheel_directory / WHEEL_NAME
        with zipfile.ZipFile(wheel_path, "w", compression=zipfile.ZIP_DEFLATED) as wheel:
            for path in sorted(stage.rglob("*")):
                if path.is_file():
                    wheel.write(path, path.relative_to(stage).as_posix())
    return WHEEL_NAME
