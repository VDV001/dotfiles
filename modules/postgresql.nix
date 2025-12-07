{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        postgresql
        pgcli
      ];
    };
}
