{
  homeModule =
    { config, ... }:
    {
      # ── Secrets ────────────────────────────────────────────────
      sops.secrets.ref_api_key = { };
      sops.secrets.magic_21st_api_key = { };
      sops.secrets.figma_api_key = { };

      # ── MCP servers with secrets → ~/.mcp.json (via sops) ─────
      sops.templates."mcp.json" = {
        path = "${config.home.homeDirectory}/.mcp.json";
        content = builtins.toJSON {
          mcpServers = {
            # Documentation search
            Ref = {
              type = "http";
              url = "https://api.ref.tools/mcp";
              headers = {
                x-ref-api-key = config.sops.placeholder.ref_api_key;
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
          # Web to MCP converter
          web-to-mcp = {
            type = "http";
            url = "https://web-to-mcp.com/mcp/4db00515-c569-46ef-97d3-26ae8f8fe865/";
          };

          # Browser automation
          playwright = {
            command = "npx";
            args = [
              "-y"
              "@playwright/mcp@latest"
            ];
            type = "stdio";
          };

          # Magic UI components
          magic-ui = {
            command = "npx";
            args = [
              "-y"
              "@magicuidesign/mcp@latest"
            ];
            type = "stdio";
          };

          # Nx workspace tools
          nx-mcp = {
            command = "npx";
            args = [
              "-y"
              "nx-mcp@latest"
            ];
            type = "stdio";
          };

          # Sequential thinking for complex problems
          sequential-thinking = {
            command = "npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-sequential-thinking"
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
        commands = {
          improve = ''
            ---
            description: Улучшает промпт, переводит на английский и оптимизирует для экономии токенов
            argument-hint: ваш промпт на русском или английском
            ---

            Ты - эксперт по улучшению промптов. Твоя задача - взять промпт пользователя и улучшить его по следующим критериям:

            ## Критерии улучшения:

            1. **Clarity (Ясность)**: Сделай промпт более чётким и понятным
            2. **Specificity (Конкретность)**: Добавь конкретные детали, если промпт слишком общий
            3. **Structure (Структура)**: Организуй промпт логически
            4. **Context (Контекст)**: Добавь необходимый контекст, если его не хватает
            5. **Actionability (Действенность)**: Сформулируй чёткие действия
            6. **Token Efficiency (Экономия токенов)**: Убери лишние слова, сохраняя смысл

            ## Процесс улучшения:

            1. **Анализ**: Определи основную цель промпта
            2. **Перевод**: Если промпт на русском - переведи на английский
            3. **Улучшение**: Примени критерии выше
            4. **Оптимизация**: Сократи без потери смысла

            ## Формат ответа:

            Верни результат в следующем формате:

            ```
            АНАЛИЗ ОРИГИНАЛЬНОГО ПРОМПТА:
            - Язык: [русский/английский]
            - Основная цель: [краткое описание]
            - Проблемы: [что нужно улучшить]

            УЛУЧШЕННЫЙ ПРОМПТ:
            [улучшенный промпт на английском языке]

            УЛУЧШЕНИЯ:
            - [что было улучшено]
            - [какие токены сэкономлены]
            - [что добавлено для ясности]

            РЕКОМЕНДАЦИИ:
            [дополнительные советы по использованию этого промпта]
            ```

            ## Важно:

            - Если промпт уже на английском и качественный - скажи об этом
            - Если промпт технический - сохрани техническую терминологию
            - Если промпт для кода - добавь контекст о языке программирования
            - Фокусируйся на экономии токенов без потери смысла

            ---

            **Промпт для улучшения:**
          '';
        };
      };
    };
}
