{
  description = "dfjay flake config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mac-app-util.url = "github:hraban/mac-app-util";
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, nix-vscode-extensions, stylix, disko, impermanence, mac-app-util, ... }:
  {
    # darwin-rebuild build --flake .#MacBook-Air-daniil
    darwinConfigurations = {
      "MacBook-Air-daniil" = 
        let
          username = "daniil";  
          useremail = "daniilvdovin4@gmail.com";
          specialArgs = inputs // { inherit inputs username useremail; };
        in
        nix-darwin.lib.darwinSystem {
          inherit specialArgs;
          modules = [ 
            ({ pkgs, lib, ... }: {
              # Set Git commit hash for darwin-version.
              system.configurationRevision = self.rev or self.dirtyRev or null;

              # $ darwin-rebuild changelog
              system.stateVersion = 6;
              system.primaryUser = username;

              nixpkgs.hostPlatform = "aarch64-darwin";

              nixpkgs.overlays = [ inputs.nix-vscode-extensions.overlays.default ];
              
              users.users.daniil = {
                name = username;
                home = "/Users/${username}";
              };
            })

            stylix.darwinModules.stylix
            ./hosts/macos
            mac-app-util.darwinModules.default
            home-manager.darwinModules.home-manager
            {
              home-manager.sharedModules = [
                mac-app-util.homeManagerModules.default
              ];
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = specialArgs;
              home-manager.users.${username} = import ./hosts/macos/home.nix;
            }
          ];
        };
    };
  };
}
