# StageX build

This StageX `user` package builds the Linux Salvium wallet C API from source.
It locks the wrapper, Salvium core, every nested source, Patchutils, Unbound,
Boost 1.86, and the direct StageX images. Boost 1.86 matches the Nix build and
preserves the Asio API expected by this Salvium revision. Compilation runs
without networking.

Use StageX commit `9bdf430d09ce2ba53932df0182faef00d4feecd1`:

```sh
cp -R stagex /path/to/stagex/packages/user/stack-wallet-cs-salvium
cd /path/to/stagex
git add packages/user/stack-wallet-cs-salvium
make fetch PKG=stack-wallet-cs-salvium
make user-stack-wallet-cs-salvium NOCACHE=1
python3 src/package-digests.py user-stack-wallet-cs-salvium
```

Build from clean checkouts on two independent builders and compare the OCI
manifest digest. The StageX artifact targets musl Linux and is independent of
the glibc-linked Nix artifact.
