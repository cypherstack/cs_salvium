{
  description = "Reproducible Linux native library build for cs_salvium";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    monero-c = { url = "github:salvium/monero_c/a63d46b74447cef2d8baa94adbd288cd9f41a2a7"; flake = false; };
    salvium = { url = "github:salvium/salvium/f8c4aed4ff86b4d8a8993e43d14140293012320a"; flake = false; };
    miniupnp = { url = "github:miniupnp/miniupnp/544e6fcc73c5ad9af48a8985c94f0f1d742ef2e0"; flake = false; };
    mx25519 = { url = "github:tevador/mx25519/e808a6406b254091f4ed83bf8ea35f032da7f0b7"; flake = false; };
    rapidjson = { url = "github:Tencent/rapidjson/129d19ba7f496df5e33658527a7158c79b99c21c"; flake = false; };
    supercop = { url = "github:monero-project/supercop/633500ad8c8759995049ccd022107d1fa8a1bbc9"; flake = false; };
    randomx = { url = "git+https://github.com/MrCyjaneK/RandomX?rev=ce72c9bb9cb799e0d9171094b9abb009e04c5bfc"; flake = false; };
    bc-ur = { url = "git+https://github.com/MrCyjaneK/bc-ur?rev=d82e7c753e710b8000706dc3383b498438795208"; flake = false; };
    polyseed = { url = "git+https://github.com/tevador/polyseed?rev=bd79f5014c331273357277ed8a3d756fb61b9fa1"; flake = false; };
    utf8proc = { url = "git+https://github.com/JuliaStrings/utf8proc?rev=3de4596fbe28956855df2ecb3c11c0bbc3535838"; flake = false; };
  };

  outputs = { self, nixpkgs, monero-c, salvium, miniupnp, mx25519, rapidjson, supercop, randomx, bc-ur, polyseed, utf8proc }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          hostAbi = if system == "x86_64-linux"
            then "x86_64-linux-gnu"
            else "aarch64-linux-gnu";
        in {
          cs-salvium = pkgs.stdenv.mkDerivation {
            pname = "cs-salvium-native";
            version = "2.0.0";
            src = monero-c;

            nativeBuildInputs = [ pkgs.cmake pkgs.gitMinimal pkgs.patchutils pkgs.pkg-config ];
            buildInputs = [
              pkgs.boost186
              pkgs.libsodium
              pkgs.openssl
              pkgs.readline
              pkgs.unbound
              pkgs.zeromq
              pkgs.zlib
            ];

            postPatch = ''
              chmod -R u+w .
              rm -rf salvium
              cp -a ${salvium} salvium
              chmod -R u+w salvium
              git -C salvium init -q

              for patchFile in ${monero-c}/patches/salvium/*.patch; do
                echo "applying $(basename "$patchFile")"
                filteredPatch="$(mktemp)"
                extraFilter=()
                if [ "$(basename "$patchFile")" = "0017-serialize-cache-to-JSON.patch" ]; then
                  extraFilter=(-x '*/src/wallet/api/wallet2_api.h')
                fi
                filterdiff \
                  -x '*/.gitmodules' \
                  -x '*/external/randomx' \
                  -x '*/external/bc-ur' \
                  -x '*/external/polyseed' \
                  -x '*/external/utf8proc' \
                  "''${extraFilter[@]}" \
                  "$patchFile" > "$filteredPatch"
                if grep -q '^--- ' "$filteredPatch"; then
                  patch -d salvium -p1 --batch --fuzz=3 < "$filteredPatch"
                fi
              done

              substituteInPlace salvium/src/wallet/api/wallet2_api.h \
                --replace-fail \
                '    //! get yield information' \
                $'    //! serialize wallet cache to JSON\n    virtual std::string serializeCacheToJson() const = 0;\n\n    //! get yield information'

              rm -rf salvium/external/{miniupnp,mx25519,rapidjson,supercop,randomx,bc-ur,polyseed,utf8proc}
              cp -a ${miniupnp} salvium/external/miniupnp
              cp -a ${mx25519} salvium/external/mx25519
              cp -a ${rapidjson} salvium/external/rapidjson
              cp -a ${supercop} salvium/external/supercop
              cp -a ${randomx} salvium/external/randomx
              cp -a ${bc-ur} salvium/external/bc-ur
              cp -a ${polyseed} salvium/external/polyseed
              cp -a ${utf8proc} salvium/external/utf8proc

              # The final wallet C API is shared, but its bundled polyseed
              # dependency must be linked statically so no sandbox RPATH is
              # retained in the deliverable.
              substituteInPlace salvium/external/polyseed/CMakeLists.txt \
                --replace-fail 'if (STATIC)' 'if (TRUE)'

              git apply --whitespace=nowarn ${./patches/fix-av.patch}
            '';

            cmakeFlags = [
              "-DHOST_ABI=${hostAbi}"
              "-DARCH=default"
              "-DMONERO_FLAVOR=salvium"
              "-DMANUAL_SUBMODULES=ON"
              "-DUSE_DEVICE_TREZOR=OFF"
              "-DBUILD_GUI_DEPS=ON"
              "-DBUILD_TESTS=OFF"
              "-DBUILD_DOCUMENTATION=OFF"
              "-DReadline_ROOT_DIR=${pkgs.readline.dev}"
            ];
            cmakeDir = "../salvium_libwallet2_api_c";

            env = {
              SOURCE_DATE_EPOCH = "1";
              NIX_CFLAGS_COMPILE = "-ffile-prefix-map=/build/source=. -fdebug-prefix-map=/build/source=.";
              NIX_LDFLAGS = "--build-id=none";
            };

            installPhase = ''
              runHook preInstall
              install -Dm755 libwallet2_api_c.so "$out/lib/libsalvium_libwallet2_api_c.so"
              install -Dm644 ../salvium_libwallet2_api_c/src/main/cpp/wallet2_api_c.h \
                "$out/include/wallet2_api_c.h"
              runHook postInstall
            '';

            doCheck = false;
          };

          default = self.packages.${system}.cs-salvium;
        });

      checks = forAllSystems (system: {
        inherit (self.packages.${system}) cs-salvium;
      });
    };
}
