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
    { ... }:
    {
      sops = defaultSopsConfig;
    };
}
