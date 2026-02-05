# INTRO
Proof-of-concept implementation of an AFF4 backend used by The Sleuth Kit (TSK), plus a C# P/Invoke mapping.

## Dependencies
- https://github.com/mnovak001/aff4-cpp-lite
- https://github.com/sleuthkit/sleuthkit

## Build (Makefile, no CMake)
This repository now builds directly with `make`.

### Native build
```bash
make
```

Artifacts:
- `libaff4tsk.so`
- `test_aff4tsk`

### Nix build environment
A `shell.nix` is included to pull in:
- `sleuthkit` from nixpkgs
- `aff4-cpp-lite` built from `mnovak001/aff4-cpp-lite`

```bash
nix-shell
make
```

The shell exports:
- `NIX_AFF4_CPP_LITE`
- `NIX_SLEUTHKIT`

The `Makefile` automatically uses these paths when present.

## Run test binary
```bash
LD_LIBRARY_PATH=.${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH} ./test_aff4tsk /path/to/image.aff4
```
