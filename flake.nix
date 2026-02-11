{
  description = "AFF4-TSK shared library depending on aff4-cpp-lite";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-parts.url = "github:hercules-ci/flake-parts";

    aff4-cpp-lite.url = "github:pluskal/aff4-cpp-lite";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, aff4-cpp-lite, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      perSystem = { system, pkgs, ... }:

        let
          # Custom compiler
          customGcc = pkgs.gcc13;

          stdenv = pkgs.overrideCC pkgs.stdenv customGcc;

          aff4Pkg = aff4-cpp-lite.packages.${system}.default;

        in
        {
          packages.default = stdenv.mkDerivation {
            pname = "aff4-tsk-poc";
            version = "1.0";

            src = ./.;

            buildInputs = [
              aff4Pkg
              pkgs.sleuthkit
            ];

            nativeBuildInputs = [
              customGcc
              pkgs.binutils
            ];

            dontConfigure = true;
            dontFixup = true;

            buildPhase = ''
              runHook preBuild

              mkdir -p build

              echo "Compiling aff4_tsk_img.c"

              ${customGcc}/bin/gcc \
                -std=gnu17 \
                -O2 \
                -fPIC \
                -I${aff4Pkg}/include \
                -I${pkgs.sleuthkit}/include \
                -I. \
                -c aff4_tsk_img.c \
                -o build/aff4_tsk_img.o

              echo "Linking aff4_tsk_img.so"

              ${customGcc}/bin/gcc \
                -shared \
                -Wl,-soname,aff4_tsk_img.so \
                -o build/aff4_tsk_img.so \
                build/aff4_tsk_img.o \
                -L${aff4Pkg}/lib \
                -L${pkgs.sleuthkit}/lib \
                -laff4 \
                -ltsk \
                -Wl,-rpath,${aff4Pkg}/lib:${pkgs.sleuthkit}/lib

              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out/lib
              mkdir -p $out/include

              cp build/aff4_tsk_img.so $out/lib/

              if ls *.h 1> /dev/null 2>&1; then
                cp *.h $out/include/
              fi

              runHook postInstall
            '';
          };
        };
    };
}
