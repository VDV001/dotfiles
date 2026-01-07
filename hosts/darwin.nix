{ inputs, lib, ... }:
let
  self-lib = import ../lib.nix { inherit lib; };
  inherit (self-lib) modules getHomeModules getDarwinModules;

  mkDarwinConfiguration =
    {
      host,
      user,
      useremail ? "daniilvdovin4@gmail.com",
      system,
      homeModules ? [ ],
      darwinModules ? [ ],
      hostModules ? [ ],
    }:
    let
      pkgs-master = import inputs.nixpkgs-master {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = inputs // {
        inherit inputs;
        username = user;
        inherit useremail pkgs-master;
      };
    in
    {
      flake.darwinConfigurations.${host} = inputs.nix-darwin.lib.darwinSystem {
        inherit specialArgs;
        modules = [
          (
            { ... }:
            {
              system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
              system.stateVersion = 6;
              system.primaryUser = user;
              nixpkgs.hostPlatform = system;
              nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
              users.users.${user} = {
                name = user;
                home = "/Users/${user}";
              };
            }
          )
          inputs.stylix.darwinModules.stylix
          inputs.sops-nix.darwinModules.sops
        ]
        ++ getDarwinModules darwinModules
        ++ hostModules
        ++ [
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              inputs.nix4nvchad.homeManagerModules.default
              inputs.sops-nix.homeManagerModules.sops
            ];
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${user} =
              { ... }:
              {
                imports = getHomeModules homeModules;
                home = {
                  username = user;
                  homeDirectory = "/Users/${user}";
                  stateVersion = "25.11";
                };
                programs.home-manager.enable = true;
              };
          }
        ];
      };
    };

in
{
  imports = [
    (mkDarwinConfiguration {
      host = "MacBook-Air-daniil";
      user = "daniil";
      system = "aarch64-darwin";
      darwinModules = with modules; [
        darwin-system
      ];
      homeModules = with modules; [
        sops
        claude
        bat
        docker
        eza
        fastfetch
        formats
        git
        htop
        k8s
        kitty
        lazydocker
        lazygit
        nvchad
        postgresql
        proto
        ripgrep
        skim
        ssh
        starship
        translateshell
        yazi
        zoxide
        zsh
        languages.go
        languages.js
        languages.python
      ];
      hostModules = [ ./daniil-laptop ];
    })
  ];
}
