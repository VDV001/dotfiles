{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        solc
      ];
    };
}
