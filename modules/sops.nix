let
  defaultSopsConfig = {
    defaultSopsFile = ../secrets/secret.yaml;
    defaultSopsFormat = "yaml";
  };
in
{
  nixosModule =
    { ... }:
    {
      sops = defaultSopsConfig;
    };

  homeModule =
    { config, ... }:
    {
      sops = defaultSopsConfig // {
        age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
      };
    };
}
