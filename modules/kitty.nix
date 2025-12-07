{
  homeModule =
    { ... }:

    {
      programs.kitty = {
        enable = true;
        shellIntegration.enableZshIntegration = true;
        settings = {
        };
      };
    };
}
