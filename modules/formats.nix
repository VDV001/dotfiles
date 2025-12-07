{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        taplo
        vscode-langservers-extracted
        yaml-language-server
      ];
    };
}
