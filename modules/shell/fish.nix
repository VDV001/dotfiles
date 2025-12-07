{
  nixosModule =
    { pkgs, username, ... }:

    {
      users.users.${username} = {
        shell = pkgs.fish;
      };

      programs.fish.enable = true;
    };
}
