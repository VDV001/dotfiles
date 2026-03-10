{
  homeModule =
    { config, ... }:
    {
      sops.secrets."netrc" = {
        path = "${config.home.homeDirectory}/.netrc";
      };
    };
}
