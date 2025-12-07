{
  homeModule =
    { ... }:
    {
      programs.zsh = {
        enable = true;
        autocd = false;
        enableCompletion = true;
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;

        sessionVariables = {

        };

        oh-my-zsh = {
          enable = true;
          plugins = [
            "docker"
            "git"
            "golang"
            "gradle"
            "helm"
            "kitty"
            "kubectl"
            "macos"
            "npm"
            "podman"
            "rust"
            "ssh"
            "systemd"
            "vagrant"
            "pip"
          ];
          theme = "robbyrussell";
        };

        shellAliases = {
          ll = "eza -la --sort name --group-directories-first --no-permissions --no-filesize --no-user --no-time";
          edit = "sudo -e";
          tree = "eza --tree";
        };

        history = {
          size = 10000;
          ignoreAllDups = true;
          ignorePatterns = [
            "rm *"
            "pkill *"
            "cp *"
          ];
        };
      };
    };
}
