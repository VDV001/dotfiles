{
  homeModule =
    { lib, ... }:
    {
      # kb-engine — движок базы знаний и личных финансов (~/git/kb-engine).
      #
      # Флаги у него длинные, а забытый флаг стоит пустой вкладки: движок с
      # версии 0.9.0 говорит при старте, каких источников ему не дали, но
      # набирать девять путей руками каждый раз всё равно не нужно.
      #
      # Пути объявлены один раз, в переменных ниже, и обе команды — терминал и
      # дашборд — читают их оттуда. Вторая копия списка путей однажды научила бы
      # один интерфейс одному, а другой другому.
      programs.zsh.initContent = lib.mkAfter ''
        # --- kb-engine -----------------------------------------------------
        export KB_HOME="$HOME/claude-cowork"
        export KB_DATA="$KB_HOME/knowledge-base/_data"
        export KB_CATALOG="$KB_DATA/catalog.json"
        export KB_LEDGER="$KB_HOME/finances/transactions.jsonl"
        export KB_BOOK="$KB_HOME/finances/Учёт_финансов.xlsx"
        export KB_SRC="$HOME/git/kb-engine"

        # kb — база в терминале: поиск, карточка, правка состояния и вердикта,
        # Tab — финансы, на них a — расход, i — доход.
        # --from обязателен: без книги терминал не видит балансов счетов и не
        # показывает клавиши b (баланс) и s (догнать книгу). Экран финансов при
        # этом выглядит рабочим, просто беднее — заметить пропажу можно только
        # сравнив его с вебом, что однажды и пришлось делать.
        kb() { kbengine tui --catalog "$KB_CATALOG" --ledger "$KB_LEDGER" --from "$KB_BOOK" "$@"; }

        # kbweb — дашборд со всеми источниками. Порт 8097, только 127.0.0.1:
        # с --ledger процесс отдаёт четыре года личных операций.
        kbweb() {
          kbengine serve --addr 127.0.0.1:8097 \
            --catalog "$KB_CATALOG" \
            --analytics-config "$KB_DATA/analytics_config.json" \
            --projects "$KB_DATA/projects.json" \
            --team "$KB_DATA/team.json" \
            --media "$KB_DATA/media" \
            --ledger "$KB_LEDGER" \
            --from "$KB_BOOK" \
            --now "$KB_HOME/memory/active-pipeline.md" \
            --changelog "$KB_HOME/knowledge-base/CHANGELOG.md" \
            --maps "$HOME/git/kb-engine/docs/architecture-map/map.json" \
            --maps "$KB_HOME/docs/architecture-map/map.json" \
            --maps "$HOME/git/kb-engine/docs/architecture-map-cloud/map.json" "$@"
        }

        # Финансы. kbadd/kbincome пишут в ledger, kbsync переносит в книгу —
        # книга сама себя не догоняет.
        kbfin()    { kbengine fin report --ledger "$KB_LEDGER" "$@"; }
        kbls()     { kbengine fin list   --ledger "$KB_LEDGER" "$@"; }
        kbadd()    { kbengine fin add    --ledger "$KB_LEDGER" --kind expense "$@"; }
        kbincome() { kbengine fin add    --ledger "$KB_LEDGER" --kind income  "$@"; }
        kbsync()   { kbengine fin sync   --ledger "$KB_LEDGER" --from "$KB_BOOK" "$@"; }

        # Каталог.
        kbaudit() { kbengine audit --catalog "$KB_CATALOG" "$@"; }
        kbdedup() { kbengine dedup --catalog "$KB_CATALOG" "$@"; }
        kbdrift() { kbengine drift --catalog "$KB_CATALOG" "$@"; }
        kbset()   { kbengine set   --catalog "$KB_CATALOG" "$@"; }
        kbnew()   { kbengine add   --catalog "$KB_CATALOG" "$@"; }

        # --- поиск со смысловым слоем --------------------------------------
        # Три слоя (v0.24.0): подстрока · транслитерация и опечатки · словарь
        # синонимов; четвёртый, смысловой, включается только когда есть индекс
        # и служба эмбеддингов.
        #
        # Модель названа здесь и ТОЛЬКО здесь: порог близости принадлежит
        # модели, а не движку — у другой своя шкала, и умолчание 0.50, снятое
        # замером на bge-m3, там будет означать другое.
        export KB_EMBED_MODEL="bge-m3"
        export KB_EMBED_URL="http://127.0.0.1:11434/api/embeddings"

        # kbollama — поднять службу эмбеддингов, если она не отвечает.
        #
        # Отдельной функцией, потому что автозапуска у неё нет: brew ставит
        # ollama, но services у неё "none", и сервер не поднимается сам. Молча
        # искать без смыслового слоя тоже нельзя — движок скажет, что слоя нет,
        # и человек решит, что база пуста.
        kbollama() {
          if curl -sf -m 2 "''${KB_EMBED_URL%/api/embeddings}/api/tags" >/dev/null 2>&1; then
            return 0
          fi
          if ! command -v ollama >/dev/null 2>&1; then
            echo "ollama не найдена — смыслового слоя не будет" >&2
            return 1
          fi
          echo "поднимаю ollama…" >&2
          (ollama serve >/dev/null 2>&1 &)
          for _ in 1 2 3 4 5 6 7 8 9 10; do
            sleep 1
            curl -sf -m 2 "''${KB_EMBED_URL%/api/embeddings}/api/tags" >/dev/null 2>&1 && return 0
          done
          echo "ollama не ответила за 10 секунд — ищу без смыслового слоя" >&2
          return 1
        }

        # kbfind — поиск по базе всеми слоями. Запрос словами, без кавычек:
        #   kbfind почему падает контейнер
        kbfind() {
          kbollama
          kbengine search --catalog "$KB_CATALOG" \
            --embed-url "$KB_EMBED_URL" --embed-model "$KB_EMBED_MODEL" --q "$*"
        }

        # kbindex — пересобрать векторный индекс (рядом с каталогом, ~22 МБ).
        # Нужен после заметного пополнения базы: индекс производный и о новых
        # записях не знает, а движок об этом не предупреждает — он сравнивает с
        # тем, что в индексе есть.
        kbindex() {
          kbollama || return 1
          kbengine search --catalog "$KB_CATALOG" --build-index \
            --embed-url "$KB_EMBED_URL" --embed-model "$KB_EMBED_MODEL"
        }

        # kbdrill — тренажёр объяснения: случайная запись базы, 15 минут
        # разбора, минута вслух. Сам скрипт живёт в базе, а не здесь: он читает
        # каталог и пишет рядом с ним, в explanations/.
        #
        #   kbdrill            выпадает запись, дальше 15 минут
        #   kbdrill rec [сек]  записать голос с микрофона и сразу сохранить
        #   kbdrill save -     то же текстом, если говорить негде
        #   kbdrill stats      что известно и — отдельно — чего мы не знаем
        #
        # Запись НЕ удаляется после расшифровки: whisper слышит не всё, и
        # переслушать свой же ответ бывает важнее расшифровки. Путь печатается.
        kbdrill() {
          local script="$KB_HOME/knowledge-base/_tools/review_drill.py"
          case "''${1:-pick}" in
            rec)
              local secs="''${2:-60}"
              local f="$KB_HOME/knowledge-base/explanations/rec-$(date +%Y-%m-%dT%H-%M-%S).wav"
              mkdir -p "$(dirname "$f")"
              echo "говори — ''${secs} секунд"
              ffmpeg -hide_banner -loglevel error -f avfoundation -i ":0" \
                -t "$secs" -y "$f" </dev/null || return 1
              python3 "$script" save "$f"
              echo "запись: $f"
              ;;
            *)
              python3 "$script" "$@"
              ;;
          esac
        }

        # kbup — обновить исходники и пересобрать движок. Каждый шаг заведён
        # после своей поломки, а не про запас:
        #   pull         — 04.08 дважды вышло «обновил, а фичи нет»: PR в main
        #                  был, рабочая копия о нём не знала, и kbup молчал;
        #   fetch --tags — тег ставится через API, локально его нет, и сборка
        #                  называет ПРЕДЫДУЩИЙ выпуск (v0.15.1-0.… при живом
        #                  v0.16.0). Врёт при этом одна версия, но на неё
        #                  опирается проверка свежести витрин — и она обвиняет
        #                  правильную страницу в том, что отстала сборка;
        #   just web     — веб-бандл в git не лежит, без него go build упадёт.
        # Ставятся ОБА бинаря: kbengine-mcp появился отдельной командой, и пока
        # kbup ставил только основной, фича существовала в репозитории и не
        # существовала в терминале — тот же класс, что валидатор карт без
        # вызывающего. Версии печатаются рядом: разъехавшись, они дали бы
        # «поиск отвечает по-разному» без видимой причины.
        # Последняя строка печатает собранную версию рядом с последним тегом:
        # расхождение видно сразу, без ярлыка — читать его человеку.
        kbup() {
          (
            set -e
            cd "$KB_SRC"
            git pull --ff-only
            git fetch --tags --force
            just web
            go install ./cmd/kbengine ./cmd/kbengine-mcp
            echo "собрано: $(kbengine version | head -1) · mcp: $(kbengine-mcp --version 2>&1 | head -1) · последний тег: $(git describe --tags --abbrev=0)"
          )
        }
      '';
    };
}
