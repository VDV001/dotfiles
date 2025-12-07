{
  homeModule =
    { ... }:

    {
      programs.translate-shell = {
        enable = true;
        settings = {
          hl = "en";
          tl = [ "ru" ];
          verbose = true;
        };
      };
    };
}
