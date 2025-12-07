{
  homeModule =
    { ... }:

    {
      programs.firefox = {
        enable = true;

        profiles = {
          default = {

          };
        };
      };

      stylix.targets.firefox.profileNames = [ "default" ];
    };
}
