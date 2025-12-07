{
  homeModule =
    { ... }:

    {
      programs.librewolf = {
        enable = true;

        profiles = {
          default = {

          };
        };
      };

      stylix.targets.librewolf.profileNames = [ "default" ];
    };
}
