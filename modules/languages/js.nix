{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        bun
        nodejs_24
        typescript-language-server
        npm-check-updates
        tsx
      ];
    };
}
