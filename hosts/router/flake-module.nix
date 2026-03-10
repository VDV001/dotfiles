{ inputs, ... }:
{
  flake.packages.x86_64-linux.openwrt-image =
    let
      pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
    in
    pkgs.callPackage ./default.nix { };
}
