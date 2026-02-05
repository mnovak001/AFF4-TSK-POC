# INTRO:
Proof of concept implementation of AFF4 backend used by TSK library. Additionally with mapping to C# using P/Invoke.

# Dependencies
- [https://github.com/aff4/aff4-cpp-lite/tree/master](https://github.com/aff4/aff4-cpp-lite/tree/master)
- [https://github.com/sleuthkit/sleuthkit](https://github.com/sleuthkit/sleuthkit)

# Nix flake build
The repository now includes a `flake.nix` that provides two packages:

- `aff4-cpp-lite`: downloads `mnovak001/aff4-cpp-lite` and builds it with:
  - `./autogen.sh`
  - `./configure --prefix=$out`
  - `make -j$(nproc)`
- `aff4-tsk-poc` (default): builds this repository using explicit C compiler invocations (no `make`) and links against `aff4-cpp-lite` and `sleuthkit`.

Typical commands:

```bash
nix build .#aff4-cpp-lite
nix build .#aff4-tsk-poc
```
