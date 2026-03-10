{
  nixosModule =
    { ... }:
    {
      virtualisation.docker = {
        enable = true;
        rootless = {
          enable = false;
          setSocketVariable = false;
        };
      };
    };

  homeModule =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        dockerfile-language-server
        docker-compose-language-service
      ];
    };
}
