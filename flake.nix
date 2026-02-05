{
  description = "AFF4 TSK POC with aff4-cpp-lite built via nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        aff4-cpp-lite = pkgs.stdenv.mkDerivation rec {
          pname = "aff4-cpp-lite";
          version = "unstable-2026-02-05";

          src = pkgs.fetchFromGitHub {
            owner = "mnovak001";
            repo = "aff4-cpp-lite";
            rev = "master";
            hash = pkgs.lib.fakeHash;
          };

          nativeBuildInputs = with pkgs; [
            autoconf
            automake
            libtool
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
            zlib
          ];

          buildPhase = ''
            runHook preBuild
            ./autogen.sh
            ./configure --prefix=$out
            make -j"$(nproc)"
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall
            make install
            runHook postInstall
          '';
        };
      in {
        packages = rec {
          default = aff4-tsk-poc;

          inherit aff4-cpp-lite;

          aff4-tsk-poc = pkgs.stdenv.mkDerivation {
            pname = "aff4-tsk-poc";
            version = "0.1.0";
            src = ./.;

            nativeBuildInputs = with pkgs; [
              pkg-config
            ];

            buildInputs = [
              aff4-cpp-lite
              pkgs.sleuthkit
              pkgs.zlib
              pkgs.openssl
            ];

            buildPhase = ''
              runHook preBuild

              export NIX_CFLAGS_COMPILE="$NIX_CFLAGS_COMPILE -I${aff4-cpp-lite}/include -I${pkgs.sleuthkit.dev}/include"
              export NIX_LDFLAGS="$NIX_LDFLAGS -L${aff4-cpp-lite}/lib -L${pkgs.sleuthkit}/lib"

              $CC -fPIC -shared aff4_tsk_img.c -o libaff4tsk.so \
                -I${aff4-cpp-lite}/include \
                -I${pkgs.sleuthkit.dev}/include \
                -L${aff4-cpp-lite}/lib \
                -L${pkgs.sleuthkit}/lib \
                -laff4 -ltsk -lpthread

              $CC test.c -o test_aff4tsk \
                -I${aff4-cpp-lite}/include \
                -I${pkgs.sleuthkit.dev}/include \
                -L. -L${aff4-cpp-lite}/lib -L${pkgs.sleuthkit}/lib \
                -Wl,-rpath,$out/lib:${aff4-cpp-lite}/lib:${pkgs.sleuthkit}/lib \
                -laff4tsk -laff4 -ltsk -lpthread

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p $out/lib $out/bin $out/include
              cp libaff4tsk.so $out/lib/
              cp test_aff4tsk $out/bin/
              cp aff4_tsk_img.h $out/include/
              runHook postInstall
            '';
          };
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
        };
      });
}
