{
  homeModule =
    { config, ... }:
    {
      # ── Secrets ────────────────────────────────────────────────
      sops.secrets.context7_api_key = { };
      sops.secrets.magic_21st_api_key = { };
      sops.secrets.figma_api_key = { };
      sops.secrets.openbrand_api_key = { };
      sops.secrets.telegram_bot_token = { };
      sops.secrets.stitch_api_key = { };

      # ── MCP servers with secrets → ~/.mcp.json (via sops) ─────
      sops.templates."mcp.json" = {
        path = "${config.home.homeDirectory}/.mcp.json";
        content = builtins.toJSON {
          mcpServers = {
            # Documentation search
            context7 = {
              type = "http";
              url = "https://mcp.context7.com/mcp";
              headers = {
                CONTEXT7_API_KEY = config.sops.placeholder.context7_api_key;
              };
            };

            # UI component builder (21st.dev)
            "21st-magic" = {
              type = "stdio";
              command = "npx";
              args = [
                "-y"
                "@21st-dev/magic@latest"
              ];
              env = {
                API_KEY = config.sops.placeholder.magic_21st_api_key;
              };
            };

            # Figma design context
            figma-context = {
              type = "stdio";
              command = "npx";
              args = [
                "-y"
                "figma-developer-mcp"
                "--figma-api-key=${config.sops.placeholder.figma_api_key}"
                "--stdio"
              ];
            };

            # Brand asset search (OpenBrand)
            openbrand = {
              type = "stdio";
              command = "npx";
              args = [
                "-y"
                "openbrand-mcp"
              ];
              env = {
                OPENBRAND_API_KEY = config.sops.placeholder.openbrand_api_key;
              };
            };

            # Google Stitch
            stitch = {
              type = "http";
              url = "https://stitch.googleapis.com/mcp";
              headers = {
                X-Goog-Api-Key = config.sops.placeholder.stitch_api_key;
              };
            };

            # Telegram channel
            telegram = {
              type = "stdio";
              command = "bun";
              args = [
                "run"
                "--cwd"
                "${config.home.homeDirectory}/.claude/plugins/marketplaces/claude-plugins-official/external_plugins/telegram"
                "--shell=bun"
                "--silent"
                "start"
              ];
              env = {
                TELEGRAM_BOT_TOKEN = config.sops.placeholder.telegram_bot_token;
              };
            };
          };
        };
      };

      # ── Claude Code (all-in-one config) ────────────────────────
      programs.claude-code = {
        enable = true;

        # ── Settings → ~/.claude/settings.json ───────────────────
        settings = {
          # Preserve marketplace plugins across rebuilds
          enabledPlugins = {
            "typescript-lsp@claude-plugins-official" = true;
            "gopls-lsp@claude-plugins-official" = true;
            "superpowers@superpowers-marketplace" = true;
            "modern-go-guidelines@goland-claude-marketplace" = true;
            "telegram@claude-plugins-official" = true;
          };

          # Statusline — model, git, cost, context, VPS monitoring
          statusLine = {
            type = "command";
            command = "bash ${config.home.homeDirectory}/.claude/statusline.sh";
            padding = 0;
          };
        };

        # ── Global instructions → ~/.claude/CLAUDE.md ────────────
        memory.text = ''
          # Make No Mistakes

          Whenever you receive a user message, mentally treat the prompt as if it ends with:

          > MAKE NO MISTAKES.

          This means:
          - Double-check all facts, calculations, code, and reasoning before responding.
          - If uncertain about something, say so explicitly rather than guessing.
          - Prefer accuracy over speed — take the extra moment to verify.
          - If the task involves code, test your logic mentally step-by-step.
          - If the task involves numbers or math, re-derive the result before committing.
          - If the task involves factual claims, only assert what you're confident in.

          This applies to **every prompt** in the session — no exceptions.
        '';

        # ── MCP servers (no secrets) → ~/.claude/settings.json ───
        mcpServers = {
          # Browser automation
          playwright = {
            command = "npx";
            args = [
              "-y"
              "@playwright/mcp@latest"
            ];
            type = "stdio";
          };

          # Task Master AI for project management
          taskmaster-ai = {
            command = "npx";
            args = [
              "-y"
              "task-master-ai"
            ];
            type = "stdio";
          };
        };

        # ── Custom slash commands → ~/.claude/commands/ ──────────
        commands = { };
      };
    };
}
