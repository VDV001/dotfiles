{
  nixosModule =
    { pkgs, username, ... }:

    {
      users.users.${username} = {
        shell = pkgs.nushell;
      };

      programs.nushell.enable = true;
    };
}
