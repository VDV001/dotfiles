{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = [ pkgs.python314 ];

      programs.uv.enable = true;
    };
}
