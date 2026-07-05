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
          streak = "python3 $HOME/claude-cowork/streak/streak.py";
          # По умолчанию telegram OFF: пустой TELEGRAM_BOT_TOKEN= -> telegram-MCP сразу exit(1),
          # не поднимает getUpdates-поллер, не воюет за единственный слот. token-enhancer и пр. работают.
          claude = "TELEGRAM_BOT_TOKEN= command claude";
          claude-old = "TELEGRAM_BOT_TOKEN= command claude --model 'claude-opus-4-6[1m]'";
          claude-work = "CLAUDE_CONFIG_DIR=$HOME/.claude-work TELEGRAM_BOT_TOKEN= command claude";
          claude-personal = "CLAUDE_CONFIG_DIR=$HOME/.claude-personal TELEGRAM_BOT_TOKEN= command claude";
          # Telegram ON только этими спец-командами: реальный токен (из ~/.claude/channels/telegram/.env) + канал.
          # 'command claude' обходит alias 'claude', поэтому токен НЕ обнуляется.
          claude-work-tg = "CLAUDE_CONFIG_DIR=$HOME/.claude-work command claude --channels plugin:telegram@claude-plugins-official";
          claude-personal-tg = "CLAUDE_CONFIG_DIR=$HOME/.claude-personal command claude --channels plugin:telegram@claude-plugins-official";
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

        # Streak: тихий нудж ежедневной практики при открытии терминала.
        # Печатает «🔥 серия N · сегодня: <тема> - ещё не сделано» только если сегодня
        # не отмечено. Молчит после `streak done`. Всегда на виду без отдельного приложения.
        initContent = ''
          if [ -f "$HOME/claude-cowork/streak/streak.py" ]; then
            /usr/bin/python3 "$HOME/claude-cowork/streak/streak.py" --nudge 2>/dev/null
          fi
        '';
      };
    };
}
