# Backward-compatible entrypoint for `nix-shell`
(let
  flake = builtins.getFlake (toString ./.);
in
  flake.devShells.${builtins.currentSystem}.default)
