{
  homeModule =
    { pkgs, ... }:

    {
      home.packages =
        with pkgs;
        [
          bun
          nodejs_24
          typescript-language-server
        ]
        ++ (with pkgs.nodePackages; [
          npm-check-updates
          tsx
        ]);
    };
}
