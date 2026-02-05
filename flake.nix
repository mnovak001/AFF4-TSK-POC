{
  description = "AFF4 + TSK PoC dev environment with Make-based build";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            gcc
            gnumake
            pkg-config
            sleuthkit
          ];

          shellHook = ''
            export PREFIX="${pkgs.lib.getDev pkgs.sleuthkit}"
            echo "Dev shell ready. Build with: make"
            echo "NOTE: libaff4 is expected to be available in your linker path (or set PREFIX/LDFLAGS)."
          '';
        };
      });
}
