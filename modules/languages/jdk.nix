{
  homeModule =
    { pkgs, ... }:

    {
      programs.java = {
        enable = true;
      };

      home.packages = with pkgs; [
        eclipse-mat
        jdt-language-server
        keystore-explorer
        visualvm
      ];
    };
}
