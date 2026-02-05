{ pkgs ? import <nixpkgs> {} }:
let
  aff4CppLiteSrc = builtins.fetchTarball {
    # Track the requested repo's default branch.
    url = "https://github.com/mnovak001/aff4-cpp-lite/archive/refs/heads/master.tar.gz";
  };

  aff4CppLite = pkgs.stdenv.mkDerivation {
    pname = "aff4-cpp-lite";
    version = "master";
    src = aff4CppLiteSrc;

    nativeBuildInputs = [ pkgs.cmake pkgs.pkg-config ];

    cmakeFlags = [
      "-DCMAKE_BUILD_TYPE=Release"
      "-DBUILD_SHARED_LIBS=ON"
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib $out/include
      cp -av libaff4*.so* $out/lib/ 2>/dev/null || true
      cp -av include/* $out/include/ 2>/dev/null || true
      if [ -d aff4 ]; then
        mkdir -p $out/include/aff4
        cp -av aff4/*.h $out/include/aff4/ 2>/dev/null || true
      fi
      runHook postInstall
    '';
  };
in
pkgs.mkShell {
  packages = [
    pkgs.gnumake
    pkgs.pkg-config
    pkgs.gcc
    pkgs.sleuthkit
    aff4CppLite
  ];

  shellHook = ''
    export NIX_AFF4_CPP_LITE=${aff4CppLite}
    export NIX_SLEUTHKIT=${pkgs.sleuthkit}
    export LD_LIBRARY_PATH="${aff4CppLite}/lib:${pkgs.sleuthkit}/lib:$LD_LIBRARY_PATH"
    echo "Nix shell ready: AFF4=${aff4CppLite} TSK=${pkgs.sleuthkit}"
  '';
}
