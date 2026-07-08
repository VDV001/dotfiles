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
    { pkgs, username, ... }:
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
        (python3.withPackages (ps: with ps; [ yt-dlp bgutil-ytdlp-pot-provider ]))
        gh
        glab
        glow
        just
        sops
        sshpass
        bun
        xh

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
          "amneziavpn"
          "claude"
          "figma"
          "firefox"
          "gpg-suite"
          "google-chrome"
          "linearmouse"
          "logseq"
          "maccy"
          "orbstack"
          "outline-manager"
          "parallels"
          "tailscale-app"
          "telegram-desktop"
          "termius"
          "visual-studio-code"
          "zed" # готовый бинарь Zed (настройки/расширения декларативно через programs.zed-editor)
        ];
      };
    };
}
