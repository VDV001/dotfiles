{
  homeModule =
    { config, pkgs, ... }:
    {
      # ── Secrets ────────────────────────────────────────────────
      sops.secrets.context7_api_key = { };
      sops.secrets.magic_21st_api_key = { };
      sops.secrets.figma_api_key = { };
      sops.secrets.openbrand_api_key = { };
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
            "frontend-design@claude-plugins-official" = true;
          };

          # Enable MCP servers from ~/.mcp.json
          enabledMcpjsonServers = [
            "21st-magic"
            "context7"
            "figma-context"
            "openbrand"
            "stitch"
          ];
          enableAllProjectMcpServers = true;

          # Handoff reminder hook
          hooks = {
            SessionStart = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "python3 ~/.claude/hooks/session_start.py";
                  }
                ];
              }
            ];
            Stop = [
              {
                matcher = "";
                hooks = [
                  {
                    type = "command";
                    command = "python3 ~/.claude/hooks/stop.py";
                  }
                ];
              }
            ];
          };

          # Statusline — model, git, cost, context, VPS monitoring
          statusLine = {
            type = "command";
            command = "bash ${config.home.homeDirectory}/.claude/statusline.sh";
            padding = 0;
          };
        };

        # ── Global instructions → ~/.claude/CLAUDE.md ────────────
        context = ''
          # Глобальный CLAUDE.md — Даниил

          ## Make No Mistakes

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

          ## Кто я
          Даниил, разработчик. Готовлюсь к роли тимлида.
          Интересы: экосистема Claude, AI-агенты, vibe coding, менеджмент, архитектура ПО.
          Основной язык — Go (в перспективе). Сейчас активный проект: freelance-hub (Next.js, TypeScript, Turborepo).

          ## Общение
          - Общаться на русском
          - Конкретика важнее общих слов
          - Без длинных вступлений — сразу к делу
          - Не переспрашивать очевидное — действовать

          ## Красные линии (Red Lines)
          - **Никогда не удалять файлы** без явного подтверждения "удали это"
          - **Не менять конфиги** если значение выглядит странно — сначала понять, потом менять
          - **Не пушить** в main/master напрямую
          - **Один SSH-коннект** на сессию — не открывать новые для каждой проверки
          - **Не "чинить" работающее** — если что-то работает и не просили трогать, не трогать

          ## Безопасность
          - min-release-age=7 в .npmrc (supply chain defense)
          - Не устанавливать пакеты моложе 7 дней без явного запроса

          ## Handoffs
          В конце каждой сессии длиннее 15 минут записывать handoff в папку `.claude/handoffs/YYYY-MM-DD_тема.md`:
          - Что сделано
          - Что НЕ сработало (важнее всего)
          - Следующий шаг (один конкретный)
          - Нюансы которые важно помнить

          В начале сессии — читать последний handoff если есть.

          ## Память проекта (6 слоёв)
          SessionStart хук проверяет наличие memory-файлов. Если хук сообщает "ПАМЯТЬ ПРОЕКТА — не хватает":
          - **chronicles.md** — создай немедленно, заполни 5-10 записями из git log и кода. Формат: `YYYY-MM-DD: [решение] — [почему]`
          - **MEMORY.md** — создай индекс, добавь ссылку на chronicles
          - **CLAUDE.md проекта** — предложи создать, спроси пользователя о стеке и архитектуре
          При каждом нетривиальном решении в сессии — дописывай запись в chronicles.

          ## Стиль работы
          - Детерминированные задачи (тесты, линтер, форматирование) — через shell-скрипты, не через модель
          - При дебаге: факты из кода/логов → трассировка → гипотезы → что отбросили
          - Не подтверждать свою работу самому — нужен независимый запуск/проверка

          ## TDD + DDD + Clean Architecture — механические гейты

          **Триггер:** пользователь объявил проект/фичу в парадигме TDD+DDD+Clean Architecture (или любой подмножестве). С этого момента — соблюдать через механические гейты, не на слово. Самоcертификация запрещена.

          ### TDD — гейт "два коммита на каждое поведенческое изменение"
          - Шаг 1: `test(scope): add failing test for X` — запустить, увидеть RED, закоммитить.
          - Шаг 2: `feat(scope): implement X` — запустить, увидеть GREEN, закоммитить.
          - Один коммит `feat:` вместе с тестами = провал TDD, не считается.
          - Покрытие уже написанного кода называть честно: `test: backfill coverage for X`, НЕ выдавать за TDD.
          - Table-driven tests — обязательны при ≥3 вариантах одной проверки.

          ### DDD — гейт "что я создаю: DTO или Entity/VO?"
          - Перед новым файлом в `domain/`: это DTO (публичные поля OK, суффикс `DTO` или пакет `dto/`) или Entity/VO (конструктор `NewXxx(...) (*Xxx, error)` с валидацией инвариантов)?
          - Прямое создание `&domain.X{...}` вне `domain/` пакета — запрещено.
          - Бизнес-инвариант (валидация, правила, `min≤max`) живёт ТОЛЬКО в domain. `if x.Min > x.Max` в usecase/parser/handler = инвариант не на месте.
          - Доменные ошибки: `var ErrXxx = errors.New(...)` в domain, чтобы `errors.Is` работал. Голый `errors.New(...)` внутри функции или `fmt.Errorf("access denied")` для бизнес-ошибок — запрещено.
          - Мёртвый код в domain (события/типы не подключены к pipeline) — удалить или реально внедрить, никаких "на будущее".
          - Ubiquitous language: `Tags []string` с магическими значениями → typed enum с методами.

          ### Clean Architecture — гейт "что делает этот слой?"
          - Handler: парсинг → usecase → маппинг. Запрещено: `uuid.New()`, `time.Now()`, прямые вызовы repo, ownership-проверки. Тянет — extract в usecase.
          - Repository interfaces — в пакете-потребителе (`usecase/`), НЕ в `domain/`. DIP по классике.
          - Cross-module импорты (`modules/X` из `modules/Y`) — запрещены. Только через адаптеры в `main.go` / DI-точке.
          - UI-строки (сообщения пользователю, тексты бота) — в `handler/messages`, `llm/responses` и т.п. НЕ в usecase.
          - Фоновые goroutines — только с `context.Context` для graceful shutdown.

          ### Verification — перед claim "сделано по TDD+DDD+CA"
          - Запустить `superpowers:code-reviewer` агента с жёстким промптом: "беспристрастно, без комплиментов, оценка 1-10 по каждой оси, конкретные файлы+строки".
          - Заявлять compliance только если **каждая ось ≥8/10**. Ниже — чинить по замечаниям, потом заявлять.
          - НЕ самоcертифицировать фразами "следую TDD", "DDD-подход" — только после внешнего ревью.

          ### Красные флаги — немедленная остановка и разворот
          - `&domain.Something{...}` вне `domain/`
          - Валидация/ownership в handler
          - `uuid.New()` / `time.Now()` в handler
          - UI-строки в usecase
          - Один коммит `feat:` с тестами одновременно
          - Commit message "добавил тесты для покрытия X%" = test-after, не TDD
          - Repository interface в `domain/interfaces.go`
          - "Потом подключу" события/интерфейсы в domain

          Если ловлю себя на красном флаге — СТОП, откатить, начать с правильного гейта.
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

          # Token Enhancer — strips HTML noise, saves tokens on web fetches
          token-enhancer = {
            command = "${pkgs.uv}/bin/uv";
            args = [
              "run"
              "--with"
              "xelektron-token-enhancer"
              "python"
              "-m"
              "mcp_server"
            ];
            type = "stdio";
          };

          # Figma MCP Bridge
          figma-bridge = {
            command = "npx";
            args = [
              "-y"
              "@gethopp/figma-mcp-bridge"
            ];
            type = "stdio";
          };

          # Pencil design editor
          pencil = {
            command = "${config.home.homeDirectory}/.pencil/mcp/visual_studio_code/out/mcp-server-darwin-arm64";
            args = [
              "--app"
              "visual_studio_code"
            ];
            type = "stdio";
          };
        };

        # ── Custom slash commands → ~/.claude/commands/ ──────────
        commands = { };
      };

      # ── Additional files managed by home-manager ───────────────

      # Statusline script
      home.file.".claude/statusline.sh" = {
        executable = true;
        text = ''
          #!/bin/bash
          # claude-statusline — smart status line for Claude Code
          # https://github.com/CreatmanCEO/claude-statusline
          set -eo pipefail

          CONFIG_FILE="''${CLAUDE_STATUSLINE_CONF:-$HOME/.claude/statusline.conf}"

          SHOW_MODEL="''${SHOW_MODEL:-true}"
          SHOW_COST="''${SHOW_COST:-true}"
          SHOW_CONTEXT="''${SHOW_CONTEXT:-true}"
          SHOW_LINES="''${SHOW_LINES:-true}"
          SHOW_DURATION="''${SHOW_DURATION:-true}"
          SHOW_GIT="''${SHOW_GIT:-true}"
          SHOW_VPS="''${SHOW_VPS:-false}"
          SHOW_TOKENS="''${SHOW_TOKENS:-false}"
          TMUX_BRIDGE="''${TMUX_BRIDGE:-auto}"
          TMUX_FILE="''${TMUX_FILE:-/tmp/claude-status-''${USER:-$(whoami)}}"
          CONTEXT_WARN="''${CONTEXT_WARN:-50}"
          CONTEXT_CRIT="''${CONTEXT_CRIT:-70}"
          SEPARATOR="''${SEPARATOR:- │ }"
          STYLE="''${STYLE:-plain}"
          POWERLINE_SEP="''${POWERLINE_SEP:-}"
          LANG_RU="''${LANG_RU:-false}"
          VPS_WARN_RAM="''${VPS_WARN_RAM:-80}"
          VPS_CRIT_RAM="''${VPS_CRIT_RAM:-90}"
          VPS_WARN_DISK="''${VPS_WARN_DISK:-80}"
          VPS_CRIT_DISK="''${VPS_CRIT_DISK:-90}"
          COST_MODEL="''${COST_MODEL:-auto}"
          SHOW_LIMITS="''${SHOW_LIMITS:-true}"
          LIMITS_CACHE_SEC="''${LIMITS_CACHE_SEC:-120}"
          VPS_FOCUS="''${VPS_FOCUS:-auto}"
          VPS_SERVERS=("''${VPS_SERVERS[@]}")
          VPS_MCP_MAP=("''${VPS_MCP_MAP[@]}")

          if [[ -f "$CONFIG_FILE" ]]; then source "$CONFIG_FILE"; fi

          C_RESET="\033[0m"; C_BOLD="\033[1m"; C_DIM="\033[2m"
          C_RED="\033[31m"; C_GREEN="\033[32m"; C_YELLOW="\033[33m"
          C_BLUE="\033[34m"; C_MAGENTA="\033[35m"; C_CYAN="\033[36m"
          C_WHITE="\033[37m"; C_GRAY="\033[90m"

          color_by_threshold() {
            local value="$1" warn="$2" crit="$3"
            if (( value >= crit )); then echo -n "$C_RED"
            elif (( value >= warn )); then echo -n "$C_YELLOW"
            else echo -n "$C_GREEN"; fi
          }

          calc_api_cost() {
            local model_id="$1" input_tokens="$2" output_tokens="$3"
            local input_price output_price
            case "$model_id" in
              *opus*) input_price="15.00"; output_price="75.00" ;;
              *sonnet*) input_price="3.00"; output_price="15.00" ;;
              *haiku*) input_price="0.25"; output_price="1.25" ;;
              *) input_price="3.00"; output_price="15.00" ;;
            esac
            echo "$input_tokens $output_tokens $input_price $output_price" | awk '{printf "%.2f", ($1/1000000*$3)+($2/1000000*$4)}'
          }

          get_usage_limits() {
            local cache_file="$HOME/.claude/.usage-cache.json"
            local now=$(date +%s)

            if [[ -f "$cache_file" ]]; then
              local cache_ts=$(jq -r '.cached_at // 0' "$cache_file" 2>/dev/null)
              local cache_age=$(( now - cache_ts ))
              if (( cache_age < LIMITS_CACHE_SEC )); then
                cat "$cache_file"
                return 0
              fi
            fi

            local cred_json=""
            if [[ "$(uname)" == "Darwin" ]]; then
              cred_json=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null || true)
            elif command -v secret-tool &>/dev/null; then
              cred_json=$(secret-tool lookup service "Claude Code-credentials" 2>/dev/null || true)
            elif [[ -f "$HOME/.claude/.credentials.json" ]]; then
              cred_json=$(cat "$HOME/.claude/.credentials.json" 2>/dev/null || true)
            elif [[ -f "$HOME/.claude/.credentials" ]]; then
              cred_json=$(cat "$HOME/.claude/.credentials" 2>/dev/null || true)
            elif [[ -n "''${APPDATA:-}" ]]; then
              cred_json=$(cat "$APPDATA/claude/.credentials.json" 2>/dev/null || cat "$APPDATA/claude/.credentials" 2>/dev/null || true)
            elif [[ -n "''${LOCALAPPDATA:-}" ]]; then
              cred_json=$(cat "$LOCALAPPDATA/claude/.credentials.json" 2>/dev/null || cat "$LOCALAPPDATA/claude/.credentials" 2>/dev/null || true)
            fi

            [[ -z "$cred_json" ]] && return 1

            local token=$(echo "$cred_json" | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
            [[ -z "$token" ]] && return 1

            local api_result
            api_result=$(curl -sf --max-time 3 "https://api.anthropic.com/api/oauth/usage" \
              -H "Authorization: Bearer $token" \
              -H "anthropic-beta: oauth-2025-04-20" 2>/dev/null) || return 1

            local h_util=$(echo "$api_result" | jq -r '.five_hour.utilization // empty' 2>/dev/null)
            local h_reset=$(echo "$api_result" | jq -r '.five_hour.resets_at // empty' 2>/dev/null)
            local w_util=$(echo "$api_result" | jq -r '.seven_day.utilization // empty' 2>/dev/null)

            [[ -z "$h_util" ]] && return 1

            local h_remain=$(echo "$h_util" | awk '{printf "%.0f", 100-$1}')
            local w_remain=$(echo "$w_util" | awk '{printf "%.0f", 100-$1}')

            local h_time=""
            if [[ -n "$h_reset" ]]; then
              local reset_epoch
              if date -d "$h_reset" +%s &>/dev/null; then
                reset_epoch=$(date -d "$h_reset" +%s 2>/dev/null)
              elif python3 -c "pass" &>/dev/null; then
                reset_epoch=$(python3 -c "from datetime import datetime; print(int(datetime.fromisoformat('$h_reset'.replace('Z','+00:00')).timestamp()))" 2>/dev/null)
              fi
              if [[ -n "$reset_epoch" ]]; then
                local diff=$(( reset_epoch - now ))
                if (( diff > 0 )); then
                  local hh=$(( diff / 3600 ))
                  local mm=$(( (diff % 3600) / 60 ))
                  (( hh > 0 )) && h_time="''${hh}h''${mm}m" || h_time="''${mm}m"
                fi
              fi
            fi

            mkdir -p "$(dirname "$cache_file")"
            printf '{"h_remain":%s,"w_remain":%s,"h_time":"%s","cached_at":%s}\n' "$h_remain" "$w_remain" "$h_time" "$now" > "$cache_file"
            chmod 600 "$cache_file" 2>/dev/null
            cat "$cache_file"
          }

          format_tokens() {
            local tokens="$1"
            if (( tokens >= 1000000 )); then printf "%.1fM" "$(echo "$tokens" | awk '{printf "%.1f",$1/1000000}')"
            elif (( tokens >= 1000 )); then printf "%.1fk" "$(echo "$tokens" | awk '{printf "%.1f",$1/1000}')"
            else echo "''${tokens}"; fi
          }

          format_duration() {
            local ms="$1" seconds=$(($1/1000)) minutes=$(($1/1000/60)) hours=$(($1/1000/60/60))
            if (( hours > 0 )); then
              [[ "$LANG_RU" == "true" ]] && printf "%dч%dм" "$hours" "$((minutes%60))" || printf "%dh%dm" "$hours" "$((minutes%60))"
            elif (( minutes > 0 )); then
              [[ "$LANG_RU" == "true" ]] && printf "%dмин" "$minutes" || printf "%dm" "$minutes"
            else
              [[ "$LANG_RU" == "true" ]] && printf "%dс" "$seconds" || printf "%ds" "$seconds"
            fi
          }

          input=$(cat)
          MODEL_ID=$(echo "$input" | jq -r '.model.id // "unknown"')
          MODEL_NAME=$(echo "$input" | jq -r '.model.display_name // "?"')
          COST_USD=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
          INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
          OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
          CTX_PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
          LINES_ADD=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
          LINES_DEL=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
          DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
          WORK_DIR=$(echo "$input" | jq -r '.workspace.current_dir // ""')
          TRANSCRIPT_PATH=$(echo "$input" | jq -r '.transcript_path // ""')

          segments=()

          if [[ "$SHOW_MODEL" == "true" ]]; then
            segments+=("''${C_MAGENTA}''${C_BOLD}''${MODEL_NAME}''${C_RESET}")
          fi

          if [[ "$SHOW_GIT" == "true" && -n "$WORK_DIR" ]]; then
            if git -C "$WORK_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
              GIT_BRANCH=$(git -C "$WORK_DIR" branch --show-current 2>/dev/null || echo "")
              GIT_DIRTY=""
              if ! git -C "$WORK_DIR" diff --quiet HEAD &>/dev/null 2>&1; then GIT_DIRTY="*"; fi
              if [[ -n "$GIT_BRANCH" ]]; then
                segments+=("''${C_CYAN}''${GIT_BRANCH}''${GIT_DIRTY}''${C_RESET}")
              fi
            fi
          fi

          if [[ "$SHOW_LINES" == "true" ]]; then
            if [[ "$LANG_RU" == "true" ]]; then
              segments+=("''${C_GREEN}+''${LINES_ADD}''${C_RESET}''${C_RED}/-''${LINES_DEL}''${C_RESET} ''${C_DIM}стр''${C_RESET}")
            else
              segments+=("''${C_GREEN}+''${LINES_ADD}''${C_RESET}''${C_RED}/-''${LINES_DEL}''${C_RESET}")
            fi
          fi

          if [[ "$SHOW_TOKENS" == "true" ]]; then
            IN_FMT=$(format_tokens "$INPUT_TOKENS"); OUT_FMT=$(format_tokens "$OUTPUT_TOKENS")
            segments+=("''${C_BLUE}''${IN_FMT}''${C_DIM}→''${C_RESET}''${C_BLUE}''${OUT_FMT}''${C_RESET}")
          fi

          if [[ "$SHOW_COST" == "true" ]]; then
            DISPLAY_COST=$(printf '%.2f' "$COST_USD")
            if [[ "$DISPLAY_COST" != "0.00" ]]; then
              segments+=("''${C_YELLOW}\$''${DISPLAY_COST}''${C_RESET}")
            else
              if [[ "$COST_MODEL" == "auto" ]]; then API_COST=$(calc_api_cost "$MODEL_ID" "$INPUT_TOKENS" "$OUTPUT_TOKENS")
              else API_COST=$(calc_api_cost "$COST_MODEL" "$INPUT_TOKENS" "$OUTPUT_TOKENS"); fi
              segments+=("''${C_YELLOW}~\$''${API_COST}''${C_DIM}(api)''${C_RESET}")
            fi
          fi

          if [[ "$SHOW_LIMITS" == "true" ]]; then
            LIMITS_DATA=$(get_usage_limits 2>/dev/null || true)
            if [[ -n "$LIMITS_DATA" ]]; then
              H_REMAIN=$(echo "$LIMITS_DATA" | jq -r '.h_remain // empty' 2>/dev/null)
              W_REMAIN=$(echo "$LIMITS_DATA" | jq -r '.w_remain // empty' 2>/dev/null)
              H_TIME=$(echo "$LIMITS_DATA" | jq -r '.h_time // empty' 2>/dev/null)
              if [[ -n "$H_REMAIN" ]]; then
                H_COLOR=$(color_by_threshold "$((100 - H_REMAIN))" 50 80)
                W_COLOR=$(color_by_threshold "$((100 - W_REMAIN))" 50 80)
                LIMIT_STR="''${H_COLOR}H:''${H_REMAIN}%''${C_RESET}"
                [[ -n "$H_TIME" ]] && LIMIT_STR+=" ''${C_DIM}''${H_TIME}''${C_RESET}"
                LIMIT_STR+=" ''${W_COLOR}W:''${W_REMAIN}%''${C_RESET}"
                segments+=("$LIMIT_STR")
              fi
            fi
          fi

          if [[ "$SHOW_DURATION" == "true" ]]; then
            segments+=("''${C_DIM}$(format_duration "$DURATION_MS")''${C_RESET}")
          fi

          if [[ "$SHOW_VPS" == "local" ]]; then
            RAM_PCT=""
            if command -v free &>/dev/null; then RAM_PCT=$(free | awk '/Mem:/{printf "%.0f",$3/$2*100}')
            elif command -v vm_stat &>/dev/null; then RAM_PCT=$(vm_stat | awk '/Pages active/{a=$3}/Pages wired/{w=$4}/Pages free/{f=$3}/Pages inactive/{i=$3}/Pages speculative/{s=$3}END{gsub(/\./,"",a);gsub(/\./,"",w);gsub(/\./,"",f);gsub(/\./,"",i);gsub(/\./,"",s);total=a+w+f+i+s;used=a+w;printf "%.0f",(used/total)*100}'); fi
            [[ -n "$RAM_PCT" ]] && segments+=("$(color_by_threshold "$RAM_PCT" "$VPS_WARN_RAM" "$VPS_CRIT_RAM")RAM:''${RAM_PCT}%''${C_RESET}")
            LOAD=""
            if [[ -f /proc/loadavg ]]; then LOAD=$(awk '{print $1}' /proc/loadavg); CORES=$(nproc 2>/dev/null||echo 1)
            elif command -v sysctl &>/dev/null && sysctl -n vm.loadavg &>/dev/null; then LOAD=$(sysctl -n vm.loadavg|awk '{print $2}'); CORES=$(sysctl -n hw.ncpu 2>/dev/null||echo 1); fi
            [[ -n "$LOAD" ]] && { LOAD_PCT=$(echo "$LOAD ''${CORES:-1}"|awk '{printf "%.0f",($1/$2)*100}'); segments+=("$(color_by_threshold "$LOAD_PCT" 70 90)CPU:''${LOAD}''${C_RESET}"); }
            if command -v df &>/dev/null; then
              DISK_PCT=$(df -h / | awk 'NR==2{gsub(/%/,"");print $5}'); DISK_LABEL="Disk"
              [[ "$LANG_RU" == "true" ]] && DISK_LABEL="Диск"
              segments+=("$(color_by_threshold "$DISK_PCT" "$VPS_WARN_DISK" "$VPS_CRIT_DISK")''${DISK_LABEL}:''${DISK_PCT}%''${C_RESET}")
            fi
          elif [[ "$SHOW_VPS" == "remote" || "$SHOW_VPS" == "true" ]]; then
            VPS_CACHE_DIR="''${VPS_CACHE_DIR:-/tmp}"; VPS_STALE_SEC="''${VPS_STALE_SEC:-120}"; now=$(date +%s)

            FOCUSED_VPS=""
            if [[ "$VPS_FOCUS" == "auto" && -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
              TAIL_DATA=$(tail -c 20000 "$TRANSCRIPT_PATH" 2>/dev/null || true)
              if [[ -n "$TAIL_DATA" ]]; then
                if [[ ''${#VPS_SERVERS[@]} -gt 0 ]]; then
                  last_line=0
                  for srv in "''${VPS_SERVERS[@]}"; do
                    IFS='|' read -r vps_name vps_ip _ _ _ <<< "$srv"
                    line_num=$(echo "$TAIL_DATA" | { grep -nE "\b(ssh|scp|sftp)\b.*\b''${vps_ip//./\\.}\b" || true; } | tail -1 | cut -d: -f1)
                    if [[ -n "$line_num" ]] && (( line_num > last_line )); then
                      last_line=$line_num
                      FOCUSED_VPS="$vps_name"
                    fi
                  done
                fi
                if [[ -z "$FOCUSED_VPS" && ''${#VPS_MCP_MAP[@]} -gt 0 ]]; then
                  for mapping in "''${VPS_MCP_MAP[@]}"; do
                    IFS='|' read -r vps_name mcp_name <<< "$mapping"
                    if echo "$TAIL_DATA" | grep -q "$mcp_name" 2>/dev/null; then
                      FOCUSED_VPS="$vps_name"
                    fi
                  done
                fi
              fi
            elif [[ "$VPS_FOCUS" != "auto" && "$VPS_FOCUS" != "none" ]]; then
              FOCUSED_VPS="$VPS_FOCUS"
            fi

            vps_segment=""; has_vps=false
            for cache_file in "''${VPS_CACHE_DIR}"/vps-*.json; do
              [[ -f "$cache_file" ]] || continue; has_vps=true
              vps_name=$(jq -r '.name // "?"' "$cache_file" 2>/dev/null)
              vps_status=$(jq -r '.status // "down"' "$cache_file" 2>/dev/null)
              vps_ts=$(jq -r '.timestamp // 0' "$cache_file" 2>/dev/null)
              vps_ram=$(jq -r '.ram_pct // 0' "$cache_file" 2>/dev/null)
              vps_cpu=$(jq -r '.cpu_load // "0"' "$cache_file" 2>/dev/null)
              vps_disk=$(jq -r '.disk_pct // 0' "$cache_file" 2>/dev/null)
              cache_age=$(( now - vps_ts ))
              (( cache_age > VPS_STALE_SEC )) && vps_status="stale"

              is_focused=false; focus_reason=""
              if [[ "$vps_name" == "$FOCUSED_VPS" ]]; then is_focused=true; focus_reason="active"; fi
              if [[ "$vps_status" == "warn" || "$vps_status" == "crit" || "$vps_status" == "down" ]]; then is_focused=true; focus_reason="''${focus_reason:-alert}"; fi

              case "$vps_status" in
                ok) sym="●"; color="$C_GREEN" ;; warn) sym="◉"; color="$C_YELLOW" ;;
                crit) sym="◉"; color="$C_RED" ;; down) sym="✗"; color="$C_RED" ;;
                boot) sym="↻"; color="$C_MAGENTA" ;; *) sym="?"; color="$C_GRAY" ;;
              esac

              if [[ "$is_focused" == "true" ]]; then
                active_marker=""; [[ "$focus_reason" == *active* ]] && active_marker="▶ "
                if [[ "$vps_status" == "down" ]]; then
                  [[ "$LANG_RU" == "true" ]] && vps_segment+="''${color}''${C_BOLD}''${active_marker}''${vps_name}''${sym} НЕТ СВЯЗИ''${C_RESET} " || vps_segment+="''${color}''${C_BOLD}''${active_marker}''${vps_name}''${sym} DOWN''${C_RESET} "
                else
                  vps_segment+="''${color}''${C_BOLD}''${active_marker}''${vps_name}''${sym}''${C_RESET}''${C_DIM}(''${C_RESET}"
                  vps_segment+="$(color_by_threshold "$vps_ram" "$VPS_WARN_RAM" "$VPS_CRIT_RAM")R:''${vps_ram}%''${C_RESET} "
                  vps_segment+="$(color_by_threshold "$vps_disk" "$VPS_WARN_DISK" "$VPS_CRIT_DISK")D:''${vps_disk}%''${C_RESET}"
                  vps_segment+="''${C_DIM})''${C_RESET} "
                fi
              else
                vps_segment+="''${color}''${vps_name}''${sym}''${C_RESET} "
              fi
            done
            [[ "$has_vps" == "true" ]] && { vps_segment="''${vps_segment% }"; segments+=("$vps_segment"); }
          fi

          if [[ "$SHOW_CONTEXT" == "true" ]]; then
            CTX_COLOR=$(color_by_threshold "$CTX_PCT" "$CONTEXT_WARN" "$CONTEXT_CRIT")
            if (( CTX_PCT >= CONTEXT_CRIT )); then
              CTX_LABEL="''${C_BOLD}''${CTX_COLOR}''${CTX_PCT}% ctx''${C_RESET} ''${C_RED}''${C_BOLD}/compact!''${C_RESET}"
            else
              [[ "$LANG_RU" == "true" ]] && CTX_LABEL="''${CTX_COLOR}''${CTX_PCT}% контекст''${C_RESET}" || CTX_LABEL="''${CTX_COLOR}''${CTX_PCT}% ctx''${C_RESET}"
            fi
            segments+=("$CTX_LABEL")
          fi

          output=""
          for i in "''${!segments[@]}"; do
            (( i > 0 )) && output+="''${C_DIM}''${SEPARATOR}''${C_RESET}"
            output+="''${segments[$i]}"
          done
          printf "%b" "$output"

          if [[ "$TMUX_BRIDGE" == "on" ]] || { [[ "$TMUX_BRIDGE" == "auto" ]] && [[ -n "''${TMUX:-}" ]]; }; then
            PLAIN_OUTPUT=$(printf "%b" "$output" | sed 's/\x1b\[[0-9;]*m//g')
            echo "$PLAIN_OUTPUT" > "$TMUX_FILE"
          fi
        '';
      };

      # Statusline config
      home.file.".claude/statusline.conf".text = ''
        # claude-statusline config
        SHOW_MODEL=true
        SHOW_COST=true
        SHOW_CONTEXT=true
        SHOW_LINES=true
        SHOW_DURATION=true
        SHOW_GIT=true
        SHOW_VPS=true
        SHOW_TOKENS=true
        VPS_WARN_RAM=80
        VPS_CRIT_RAM=90
        VPS_SERVERS=(
          "main|45.87.246.33|22|root|-"
        )

        LANG_RU=true

        CONTEXT_WARN=50
        CONTEXT_CRIT=70
        COST_MODEL=auto
        TMUX_BRIDGE=auto
      '';

      # SessionStart hook — loads context and checks project memory health
      home.file.".claude/hooks/session_start.py" = {
        executable = true;
        text = ''
          #!/usr/bin/env python3
          """SessionStart hook — loads context and checks project memory health."""
          import json
          import sys
          from pathlib import Path


          def get_auto_memory_dir():
              """Get the auto-memory dir for current project (~/.claude/projects/<sanitized-cwd>/memory/)."""
              cwd = Path.cwd()
              sanitized = str(cwd).replace("/", "-")
              return Path.home() / ".claude" / "projects" / sanitized / "memory"


          def find_handoffs_dir():
              """Search: project .claude/handoffs/ → ~/.claude/handoffs/."""
              cwd = Path.cwd()
              for parent in [cwd] + list(cwd.parents):
                  candidate = parent / ".claude" / "handoffs"
                  if candidate.exists():
                      return candidate
              home = Path.home() / ".claude" / "handoffs"
              if home.exists():
                  return home
              return None


          def find_chronicles():
              """Search: project memory/chronicles.md → auto-memory chronicles.md."""
              cwd = Path.cwd()
              for parent in [cwd] + list(cwd.parents):
                  candidate = parent / "memory" / "chronicles.md"
                  if candidate.exists():
                      return candidate
              auto = get_auto_memory_dir() / "chronicles.md"
              if auto.exists():
                  return auto
              return None


          def find_project_claude_md():
              """Find CLAUDE.md in project root."""
              cwd = Path.cwd()
              for parent in [cwd] + list(cwd.parents):
                  candidate = parent / "CLAUDE.md"
                  if candidate.exists() and parent != Path.home():
                      return candidate
              return None


          def check_memory_health():
              """Check what memory layers are missing for this project."""
              missing = []
              auto_memory = get_auto_memory_dir()

              # Chronicles
              if not find_chronicles():
                  missing.append(
                      "chronicles.md не найден. "
                      "Создай журнал архитектурных решений:\n"
                      f"  Путь: {auto_memory / 'chronicles.md'}\n"
                      "  Формат: YYYY-MM-DD: [решение] — [почему именно так]"
                  )

              # MEMORY.md index
              memory_index = auto_memory / "MEMORY.md"
              if not memory_index.exists():
                  missing.append(
                      "MEMORY.md (индекс памяти) не найден. "
                      "Начни вести память проекта:\n"
                      f"  Путь: {memory_index}\n"
                      "  Содержание: ссылки на memory-файлы (feedback, decisions, progress)"
                  )

              # Project CLAUDE.md
              if not find_project_claude_md():
                  missing.append(
                      "CLAUDE.md проекта не найден. "
                      "Создай файл с архитектурой, структурой и правилами проекта."
                  )

              return missing


          # ── Collect context ──────────────────────────────────────────
          messages = []

          # 1. Latest handoff
          handoffs_dir = find_handoffs_dir()
          if handoffs_dir:
              handoffs = sorted(handoffs_dir.glob("*.md"))
              handoffs = [h for h in handoffs if h.name != "TEMPLATE.md"]
              if handoffs:
                  latest = handoffs[-1]
                  messages.append(f"Последний handoff: {latest.name}")
                  messages.append(latest.read_text()[:800])

          # 2. Last 5 chronicles
          chronicles = find_chronicles()
          if chronicles:
              lines = [
                  line
                  for line in chronicles.read_text().splitlines()
                  if line.strip()
                  and not line.startswith("#")
                  and not line.startswith("---")
                  and not line.startswith("name:")
                  and not line.startswith("description:")
                  and not line.startswith("type:")
              ]
              if lines:
                  messages.append("Последние решения из chronicles:")
                  messages.append("\n".join(lines[-5:]))

          # 3. Memory health check
          missing = check_memory_health()
          if missing:
              messages.append("ПАМЯТЬ ПРОЕКТА — не хватает:")
              for item in missing:
                  messages.append(f"  - {item}")
              messages.append(
                  "Рекомендация: создай недостающие файлы в начале сессии, "
                  "чтобы контекст не терялся между сессиями."
              )

          # ── Output ───────────────────────────────────────────────────
          if messages:
              print(json.dumps({
                  "hookSpecificOutput": {
                      "hookEventName": "SessionStart",
                      "additionalContext": "\n\n".join(messages),
                  }
              }))

          sys.exit(0)
        '';
      };

      # Handoff reminder hook
      home.file.".claude/hooks/stop.py" = {
        executable = true;
        text = ''
          #!/usr/bin/env python3
          import json
          import sys
          import os
          from datetime import datetime
          from pathlib import Path

          def session_age_minutes():
              # Check parent process start time via /proc or ps
              try:
                  ppid = os.getppid()
                  # macOS: use ps to get elapsed time
                  import subprocess
                  result = subprocess.run(
                      ["ps", "-o", "etime=", "-p", str(ppid)],
                      capture_output=True, text=True, timeout=5
                  )
                  if result.returncode == 0:
                      elapsed = result.stdout.strip()
                      # Format: [[dd-]hh:]mm:ss
                      parts = elapsed.replace("-", ":").split(":")
                      parts = [int(p) for p in parts]
                      if len(parts) == 2:
                          return parts[0] + parts[1] / 60
                      elif len(parts) == 3:
                          return parts[0] * 60 + parts[1] + parts[2] / 60
                      elif len(parts) == 4:
                          return parts[0] * 24 * 60 + parts[1] * 60 + parts[2] + parts[3] / 60
                  return 999
              except Exception:
                  return 999

          def find_handoffs_dir():
              cwd = Path.cwd()
              for parent in [cwd] + list(cwd.parents):
                  candidate = parent / ".claude" / "handoffs"
                  if candidate.exists():
                      return candidate
              home_handoffs = Path.home() / ".claude" / "handoffs"
              home_handoffs.mkdir(parents=True, exist_ok=True)
              return home_handoffs

          def fresh_handoff_exists(handoffs_dir):
              today = datetime.now().strftime("%Y-%m-%d")
              if not handoffs_dir.exists():
                  return False
              for f in handoffs_dir.iterdir():
                  if f.name.startswith(today) and f.suffix == ".md":
                      return True
              return False

          def main():
              age = session_age_minutes()
              if age < 15:
                  sys.exit(0)
              handoffs_dir = find_handoffs_dir()
              if fresh_handoff_exists(handoffs_dir):
                  sys.exit(0)
              response = {
                  "decision": "block",
                  "reason": (
                      f"Сессия {int(age)} мин — handoff не записан.\n"
                      f"Запиши в {handoffs_dir}/YYYY-MM-DD_тема.md:\n"
                      f"  ## Сделано\n  ## НЕ сработало\n  ## Следующий шаг\n"
                      f"Используй шаблон: {handoffs_dir}/TEMPLATE.md"
                  )
              }
              print(json.dumps(response))
              sys.exit(0)

          if __name__ == "__main__":
              main()
        '';
      };

      # ── Skills ─────────────────────────────────────────────────

      # Finance Tracker skill
      home.file.".claude/skills/finance-tracker/SKILL.md".text = builtins.readFile ./claude-skills/finance-tracker/SKILL.md;

      # Finance Log skill
      home.file.".claude/skills/finance-log/SKILL.md".text = builtins.readFile ./claude-skills/finance-log/SKILL.md;
      home.file.".claude/skills/finance-log/finance-log-skill/SKILL.md".text = builtins.readFile ./claude-skills/finance-log/finance-log-skill/SKILL.md;

      # Codebase-to-Course skill
      home.file.".claude/skills/codebase-to-course/SKILL.md".text = builtins.readFile ./claude-skills/codebase-to-course/SKILL.md;
      home.file.".claude/skills/codebase-to-course/README.md".text = builtins.readFile ./claude-skills/codebase-to-course/README.md;
      home.file.".claude/skills/codebase-to-course/references/design-system.md".text = builtins.readFile ./claude-skills/codebase-to-course/references/design-system.md;
      home.file.".claude/skills/codebase-to-course/references/interactive-elements.md".text = builtins.readFile ./claude-skills/codebase-to-course/references/interactive-elements.md;
    };
}
