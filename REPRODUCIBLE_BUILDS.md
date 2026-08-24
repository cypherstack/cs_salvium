# Reproducible native builds

The Nix flake builds the Linux `libsalvium_libwallet2_api_c.so` consumed by
`cs_salvium_flutter_libs_linux`. It pins the Salvium `monero_c` fork, the
Salvium source and every required nested submodule, nixpkgs, and the complete
build toolchain in `flake.lock`. Network access is unavailable during builds.

```sh
nix build .#cs-salvium
./nix/verify-reproducible.sh
```

The verifier rebuilds the derivation and compares the library bytes. The
resulting library and C header are under `result/lib` and `result/include`.

This currently covers native Linux on x86-64 and AArch64. Android, Windows,
macOS, and iOS need separate pinned SDK/cross-toolchain derivations before
their checked-in release binaries can be replaced reproducibly.
