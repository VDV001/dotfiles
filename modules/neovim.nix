{
  homeModule =
    { pkgs, ... }:

    {
      programs.neovim = {
        enable = true;
        vimAlias = true;
        viAlias = true;
        defaultEditor = false;
      };
    };
}
