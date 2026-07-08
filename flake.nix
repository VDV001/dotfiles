{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      # Временно на fix-коммит PR #1819 (p42software:manual-toc-depth). Это ровно текущий
      # master (a1fa429) + одна строка: в doc/manual/default.nix `--toc-depth 1` заменён на
      # `--sidebar-depth 1`. Апстрим-master ещё шлёт флаг --toc-depth, который nixpkgs-unstable
      # убрал из nixos-render-docs, из-за чего падала деривация darwin-manual-html -> вся сборка.
      # Вернуть на "github:LnL7/nix-darwin/master", когда PR #1819 смержат (см. issue #1817).
      url = "github:p42software/nix-darwin/ebaac1f1e5cbb10ea5e9815bb1f69e53164f8b9b";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "aarch64-darwin"
      ];

      imports = [
        ./hosts/darwin.nix
      ];

      perSystem =
        { pkgs, ... }:
        {
          formatter = pkgs.nixfmt-tree;
        };
    };
}
