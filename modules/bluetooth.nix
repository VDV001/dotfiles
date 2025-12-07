{
  nixosModule =
    { ... }:

    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = false;
        settings.General.Experimental = true; # bluetooth percentage
      };
    };
}
