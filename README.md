# INTRO:
Proof of concept implementation of AFF4 backend used by TSK library. Additionally with mapping to C# using P/Invoke.

# Dependencies
- [https://github.com/aff4/aff4-cpp-lite/tree/master](https://github.com/aff4/aff4-cpp-lite/tree/master)
- [https://github.com/sleuthkit/sleuthkit](https://github.com/sleuthkit/sleuthkit)

## Build (Make, no CMake)

This repository now includes a plain `Makefile` for building the shared library and test binary without CMake.

```bash
make
```

Artifacts:
- `build/libaff4tsk.so`
- `build/test_aff4tsk`

Useful targets:
- `make lib` (build shared library only)
- `make test` (build test binary)
- `make clean`

You can override paths/toolchain via standard make variables, for example:

```bash
make PREFIX=/usr/local
```

## Nix development shell

A flake-based Nix shell is included for reproducible build tooling:

```bash
nix develop
make
```

For legacy Nix:

```bash
nix-shell
make
```

The shell provides compiler + make + sleuthkit. `libaff4` must still be available in your link/include path (or supplied via `PREFIX` / `LDFLAGS` / `CPPFLAGS`).
