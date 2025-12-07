{ inputs, lib, ... }:
let
  self-lib = import ../lib.nix { inherit lib; };
  inherit (self-lib) modules getHomeModules getNixosModules;

  # Colmena deployment targets
  colmenaHosts = {
    linode-vps = {
      targetHost = "subs.dfjay.com";
      targetUser = "dfjay";
    };
  };

  mkNixosConfiguration =
    {
      host,
      user,
      useremail ? "mail@dfjay.com",
      userdesc ? user,
      system,
      homeModules ? [ ],
      nixosModules ? [ ],
      hostModules ? [ ],
      nixpkgs ? inputs.nixpkgs,
      home-manager ? inputs.home-manager,
    }:
    let
      specialArgs = inputs // {
        inherit
          inputs
          user
          useremail
          userdesc
          host
          ;
        username = user;
        hostname = host;
      };
    in
    {
      flake.nixosConfigurations.${host} = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          (
            { ... }:
            {
              nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
            }
          )
          inputs.nix-flatpak.nixosModules.nix-flatpak
          inputs.stylix.nixosModules.stylix
          inputs.disko.nixosModules.disko
          inputs.preservation.nixosModules.preservation
          inputs.sops-nix.nixosModules.sops
        ]
        ++ getNixosModules nixosModules
        ++ hostModules
        ++ [
          home-manager.nixosModules.home-manager
          {
            home-manager.sharedModules = [
              inputs.nix4nvchad.homeManagerModules.default
              inputs.sops-nix.homeManagerModules.sops
            ];
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = specialArgs;
            home-manager.users.${user} =
              { pkgs, ... }:
              {
                imports = getHomeModules homeModules;
                home = {
                  username = user;
                  homeDirectory = "/home/${user}";
                  stateVersion = "25.11";
                  packages = with pkgs; [
                    nerd-fonts.fira-code
                    nerd-fonts.droid-sans-mono
                    nerd-fonts.noto
                    nerd-fonts.hack
                    nerd-fonts.ubuntu
                  ];
                };
                news.display = "show";
                programs.home-manager.enable = true;
              };
          }
        ];
      };
    };

in
{
  flake.colmena = let
    conf = inputs.self.nixosConfigurations;
  in {
    meta = {
      nixpkgs = import inputs.nixpkgs-stable { system = "x86_64-linux"; };
      nodeNixpkgs = builtins.mapAttrs (name: value: value.pkgs) conf;
      nodeSpecialArgs = builtins.mapAttrs (name: value: value._module.specialArgs) conf;
    };

    linode-vps = {
      deployment = {
        targetHost = colmenaHosts.linode-vps.targetHost;
        targetUser = colmenaHosts.linode-vps.targetUser;
        buildOnTarget = true;
      };
      imports = conf.linode-vps._module.args.modules;
    };
  };

  imports = [
    (mkNixosConfiguration {
      host = "linode-vps";
      user = "dfjay";
      userdesc = "Pavel Yozhikov";
      system = "x86_64-linux";
      nixpkgs = inputs.nixpkgs-stable;
      home-manager = inputs.home-manager-stable;
      nixosModules = with modules; [
        locale
      ];
      homeModules = with modules; [
        bat
        btop
        eza
        git
        helix
        ripgrep
        starship
        yazi
        zoxide
      ];
      hostModules = [ ./linode-vps ];
    })
    (mkNixosConfiguration {
      host = "dfjay-desktop";
      user = "dfjay";
      userdesc = "Pavel Yozhikov";
      system = "x86_64-linux";
      nixosModules = with modules; [
        audio
        bluetooth
        de.cosmic
        flatpak
        games
        locale
        shell.zsh
        sops
        system
        stylix
      ];
      homeModules = with modules; [
        bat
        btop
        eza
        fastfetch
        ghostty
        git
        gpg
        gradle
        helix
        k8s
        kitty
        lazydocker
        lazygit
        librewolf
        nvchad
        postgresql
        ripgrep
        skim
        starship
        translateshell
        vscode
        yazi
        zed
        zoxide
        zsh
        languages.go
        languages.js
        languages.jdk
        languages.kotlin
        languages.rust
        languages.python
      ];
      hostModules = [ ./dfjay-desktop ];
    })
  ];
}
