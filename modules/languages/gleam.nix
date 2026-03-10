{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [ gleam ];
    };
}
