inputs:

let
  inherit (inputs.nixpkgs.lib) filterAttrs const mapAttrs;
in

mapAttrs (
  directory: _:
  inputs.mixos.lib.mixosSystem {
    modules = [
      ./${directory}
      inputs.openwrt-one-nix.mixosModules.default
      {
        nixpkgs = {
          inherit (inputs) nixpkgs;
          overlays = [ inputs.self.overlays.default ];
        };
      }
    ];
  }
) (filterAttrs (const (entryType: entryType == "directory")) (builtins.readDir ./.))
