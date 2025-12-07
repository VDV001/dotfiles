{
  nixosModule =
    { pkgs, ... }:

    {
      services.displayManager.gdm = {
        enable = true;
      };

      services.desktopManager.gnome = {
        enable = true;
      };

      programs.dconf.enable = true;

      environment.gnome.excludePackages = with pkgs; [
        geary
      ];

      environment.systemPackages = with pkgs.gnomeExtensions; [
        blur-my-shell
        gsconnect
      ];
    };
}
