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

      programs.kdeconnect = {
        enable = true;
        package = pkgs.gnomeExtensions.gsconnect;
      };

      environment.gnome.excludePackages = with pkgs; [
        geary
      ];

      environment.systemPackages = with pkgs.gnomeExtensions; [
        blur-my-shell
      ];
    };
}
