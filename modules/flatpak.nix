{
  nixosModule =
    { ... }:

    {
      services.flatpak = {
        enable = true;

        update.auto.enable = false;
        uninstallUnmanaged = true;
      };
    };
}
