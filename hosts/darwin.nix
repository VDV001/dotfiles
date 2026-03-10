{ inputs, lib, ... }:
let
  self-lib = import ../lib.nix { inherit lib; };
  inherit (self-lib) modules getHomeModules getDarwinModules;

  mkDarwinConfiguration =
    {
      host,
      user,
      useremail,
      system,
      darwinStateVersion,
      homeStateVersion,
      hostModules ? [ ],
      hostConfig ? null,
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
          {
            system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
            system.stateVersion = darwinStateVersion;
            system.primaryUser = user;
            nixpkgs.hostPlatform = system;
            nixpkgs.config.allowUnfree = true;
            nixpkgs.overlays = [
              inputs.nix-vscode-extensions.overlays.default
            ]
            ++ (import ../overlays);
            users.users.${user} = {
              name = user;
              home = "/Users/${user}";
            };

            security.pam.services.sudo_local.touchIdAuth = true;

            nix = {
              gc = {
                automatic = true;
                interval = {
                  Weekday = 7;
                };
                options = "--delete-older-than 14d";
              };
              settings.experimental-features = [
                "nix-command"
                "flakes"
              ];
            };
          }
          inputs.sops-nix.darwinModules.sops
          inputs.home-manager.darwinModules.home-manager
          {
            home-manager.sharedModules = [
              inputs.sops-nix.homeManagerModules.sops
            ];
            home-manager.backupFileExtension = "backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${user} =
              { ... }:
              {
                imports = getHomeModules hostModules;
                home = {
                  username = user;
                  homeDirectory = "/Users/${user}";
                  stateVersion = homeStateVersion;
                };
              };
          }
        ]
        ++ getDarwinModules hostModules
        ++ lib.optional (hostConfig != null) hostConfig;
      };
    };

  laptop = import ./daniil-laptop { inherit modules; };

in
{
  imports = [
    (mkDarwinConfiguration {
      host = "MacBook-Air-daniil";
      inherit (laptop)
        system
        user
        useremail
        darwinStateVersion
        homeStateVersion
        ;
      hostModules = laptop.modules;
      hostConfig = laptop.config;
    })
  ];
}
