{
  homeModule =
    { config, lib, ... }:
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
          ];
        };

        shellAliases = {
          edit = "sudo -e";
          claude-old = "claude --model 'claude-opus-4-6[1m]'";
          claude-work = "CLAUDE_CONFIG_DIR=$HOME/.claude-work claude";
          claude-personal = "CLAUDE_CONFIG_DIR=$HOME/.claude-personal claude";
        }
        // lib.optionalAttrs config.programs.eza.enable {
          ll = "eza -la --sort name --group-directories-first --no-permissions --no-filesize --no-user --no-time";
          tree = "eza --tree";
        }
        // lib.optionalAttrs config.programs.bat.enable {
          cat = "bat";
        }
        // lib.optionalAttrs config.programs.btop.enable {
          top = "btop";
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
