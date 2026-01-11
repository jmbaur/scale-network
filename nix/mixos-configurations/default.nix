inputs:

let
  inherit (builtins) mapAttrs;
  inherit (inputs.nixpkgs.lib) filterAttrs const;
in

mapAttrs (
  directory: _:
  inputs.mixos.lib.mixosSystem {
    modules = [
      ./${directory}
      inputs.openwrt-one-nix.mixosModules.default
      {
        nixpkgs = {
          nixpkgs = inputs.nixpkgs-unstable; # needed for kernel 6.18, not in 25.05
          overlays = [ inputs.self.overlays.default ];
        };
      }
    ];
  }
) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))
