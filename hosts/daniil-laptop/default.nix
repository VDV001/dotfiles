{ modules }:

{
  system = "aarch64-darwin";
  user = "daniil";
  useremail = "daniilvdovin4@gmail.com";

  darwinStateVersion = 6;
  homeStateVersion = "26.05";

  modules = with modules; [
    claude
    sops
    bat
    direnv
    docker
    eza
    fastfetch
    fd
    formats
    git
    helix
    btop
    k8s
    kbengine
    kitty
    lazydocker
    lazygit
    neovim
    nix-index
    postgresql
    proto
    ripgrep
    skim
    ssh
    starship
    tealdeer
    yazi
    zoxide
    zed
    zsh

    languages.go
    languages.js
  ];

  config =
    { pkgs, pkgs-master, username, ... }:
    {
      home-manager.users.${username} = {
        sops.age.keyFile = "/Users/${username}/.config/sops/age/keys.txt";
        services.gpg-agent.pinentry.package = pkgs.pinentry_mac;
      };

      environment.systemPackages = with pkgs; [
        nh
        age
        aria2
        bash
        betterdisplay
        dive
        docker
        docker-credential-helpers
        dua
        ffmpeg
        poppler-utils # pdftotext/pdftoppm/pdfinfo — чтение и рендер PDF (резюме, доки)
        # /watch skill: yt-dlp + bgutil PO-token плагин В ОДНОМ python-env, чтобы yt-dlp грузил плагин
        # (иначе YouTube отдаёт 403 без PO-token). Пакет bgutil бандлит и node-сервер (script-режим).
        # Проверено 2026-07-03: генерит токен + качает YouTube + ffmpeg режет кадры. Пара к ffmpeg + whisper-cpp.
        # ⚠️ Взято из pkgs-master, а не из pkgs, и это временно. На 22.08.2026 канал
        # nixpkgs-unstable стоит на 391b592 (20.08 07:12 UTC) и отстаёт от master на
        # 464 коммита, а починка curl-cffi приехала в master позже: PR #554482
        # (0.15.0 → 0.16.0) в 17:21 того же дня и #554592 (install name dylib на
        # darwin) в 02:03 следующего. На канальной версии сборка падает в
        # pythonImportsCheckPhase — .so собран без LC_RPATH и не находит
        # libcurl-impersonate.4.dylib.
        # Вернуть на обычный python3, когда канал продвинется за эти коммиты:
        #   gh api repos/NixOS/nixpkgs/compare/a77731fd5319...nixpkgs-unstable
        # должен показать status=identical или ahead, а не behind.
        (pkgs-master.python3.withPackages (ps: with ps; [ yt-dlp bgutil-ytdlp-pot-provider ]))
        gh
        glab
        glow
        just
        sops
        sshpass
        bun
        xh
        bandwhich # TUI сетевых соединений по процессам (кто/куда/сколько) в реальном времени. Запуск: sudo bandwhich
        trippy # современный traceroute+ping TUI (замена mtr): маршрут до хоста, GeoIP, ICMP/UDP/TCP. Бинарь: sudo trip <host>
        doggo # современный DNS-клиент (замена dig): резолв домена/IP, DoH/DoT/DoQ, JSON. Запуск: doggo example.com

        # TUI для баз данных (ставить на dev/локальный Postgres, НЕ write на prod - оба в beta/активной разработке)
        rainfrog # 🦀 Rust TUI для БД (Postgres tier-1): vim-навигация, редактор запросов с подсветкой, история. Запуск: rainfrog --url "postgres://user:pass@localhost:5432/db"
        lazysql # Go TUI для БД в стиле lazygit (панели + hjkl, знакомый lazy-UX): Postgres/MySQL/SQLite. Запуск: lazysql

        # GUI
        bruno
        iina
      ];
      environment.variables.EDITOR = "hx";

      homebrew = {
        enable = true;

        onActivation = {
          autoUpdate = true;
          upgrade = true;
          cleanup = "zap";
          # Новый Homebrew требует подтверждения при `brew bundle --cleanup`
          # (--force / --force-cleanup / $HOMEBREW_ASK). Дописываем точечный --force-cleanup
          # через extraFlags -> `brew bundle ... --cleanup --zap --force-cleanup`.
          # --force-cleanup авторизует именно очистку (не трогает переустановки, в отличие от
          # широкого --force). Так zap сохраняется, ошибка решается штатно, а не отключается.
          extraFlags = [ "--force-cleanup" ];
        };

        masApps = {
          "TestFlight" = 899247664;
          "Keynote" = 361285480;
          "Numbers" = 361304891;
          "Pages" = 361309726;
          "Xcode" = 497799835;
        };

        taps = [ ];

        brews = [
          "ollama"
          "vercel-cli"
          "whisper-cpp" # расшифровка голосовых Telegram (whisper-cli + Metal). Объявлено,
          # чтобы cleanup=zap не сносил при ребилде. Модель: ~/models/whisper/ggml-small.bin (загружается отдельно).
        ];

        casks = [
          "anydesk"
          "amneziavpn"
          "claude"
          "figma"
          "firefox"
          "gpg-suite"
          "google-chrome"
          "linearmouse"
          "logseq"
          "telegram"
          "maccy"
          "orbstack"
          "parallels"
          "tailscale-app"
          "termius"
          "visual-studio-code"
          "zed" # готовый бинарь Zed (настройки/расширения декларативно через programs.zed-editor)
        ];
      };
    };
}
