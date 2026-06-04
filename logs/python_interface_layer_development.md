# DexMPC Python Interface Layer Development Log

## 2026-06-04

- Resumed after VS Code/Codex Terminal crash.
- Current worktree status showed a new untracked `software_stack/python/` tree, including:
  - CPython extension source: `software_stack/python/cpp/dexmpc_python_binding.cpp`
  - Python wrapper: `software_stack/python/dexmpc/runtime.py`
  - Build helper: `software_stack/python/build_python_bindings.py`
  - Built native modules for D2D and SPI transports.
- Re-read the software stack layer spec and operator interface usage document.
- Confirmed the intended Python layer direction: Python calls operator-level methods and does not build hardware registers, packed SRAM addresses, or 96-bit commands.
- Initial coverage gap: `software_stack/tests/python/` is empty, so the C++ test intent still needs to be reimplemented through Python code.
- Debug finding: importing the prebuilt native modules under Anaconda Python 3.13 failed because Anaconda's bundled `libstdc++.so.6.0.29` lacks `GLIBCXX_3.4.30`.
- Verified workaround: `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6` lets the Python process import the native modules and run a D2D SRAM round trip.
- Added Python-visible backend observability to the CPython binding:
  - `backend_kind()`
  - `transport()`
  - `read_status()`
- Added matching Python wrapper methods:
  - `Device.backend_kind()`
  - `Device.backend_transport()`
  - `Device.read_status()`
- Added `software_stack/tests/python/test_python_interface_layer.py`, a standard-library `unittest` runner that exercises the Python layer over D2D/SPI transports.
- The Python tests intentionally call the operator-level API only. They do not expose or rebuild 96-bit commands in Python, preserving the software stack layering contract.
- Rebuilt D2D and SPI native modules with `python3 software_stack/python/build_python_bindings.py --transport all`.
- Test results:
  - D2D full Python interface test passed: `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 PYTHONPATH=software_stack/python python3 software_stack/tests/python/test_python_interface_layer.py --transport d2d`
  - SPI full Python interface test timed out after 20 minutes while running the 34-case mixed operator sequence. The SPI backend smoke item had already passed before the timeout.
  - SPI limited Python interface test passed with 8 mixed cases: `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 PYTHONPATH=software_stack/python python3 software_stack/tests/python/test_python_interface_layer.py --transport spi --mixed-case-limit 8`
- Interpretation of SPI testing: this matches the existing C++ documentation pattern where SPI mixed testing is run with a smaller case count because pad-level SPI simulation is much slower than D2D.
- Added design and usage documentation: `docs/software stack/python_interface_layer_usage.md`.
- Added environment migration documentation: `docs/software stack/python_interface_environment_migration.md`.
- Made `software_stack/python/build_python_bindings.py` migration-friendly by replacing the hardcoded Verilator installation path with `VERILATOR_ROOT` / `--verilator-root`.
- Ran lightweight validation after the migration change:
  - `python3 -m py_compile software_stack/python/build_python_bindings.py software_stack/python/dexmpc/runtime.py software_stack/tests/python/test_python_interface_layer.py`
  - `python3 software_stack/python/build_python_bindings.py --help`
  - `LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 PYTHONPATH=software_stack/python python3 software_stack/tests/python/test_python_interface_layer.py --transport d2d --mixed-case-limit 1`
