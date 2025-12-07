{
  nixosModule =
    { pkgs, ... }:

    {
      services = {
        xserver = {
          enable = true;
        };
        displayManager = {
          defaultSession = "plasma";
          sddm = {
            enable = true;
            wayland.enable = true;
          };
        };
        desktopManager.plasma6 = {
          enable = true;
        };
      };

      programs.dconf.enable = true;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        konsole
      ];
    };
}
