{
  nixosModule =
    { ... }:

    {
      services.desktopManager.cosmic = {
        enable = true;
      };

      services.displayManager.cosmic-greeter = {
        enable = true;
      };

      programs.kdeconnect.enable = true;
    };
}
