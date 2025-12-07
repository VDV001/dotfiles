{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        helm-ls
        kubectl
        kubelogin-oidc
        kubecm
        kubernetes-helm
      ];

      programs.k9s = {
        enable = true;
      };
    };
}
