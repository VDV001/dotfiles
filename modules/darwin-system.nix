{
  darwinModule =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        curl
        git
        wget
      ];

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

      nixpkgs.config.allowUnfree = true;
    };
}
