{ modules }:

{
  system = "aarch64-darwin";
  user = "daniil";
  useremail = "daniilvdovin4@gmail.com";

  darwinStateVersion = 6;
  homeStateVersion = "26.05";

  modules = with modules; [
    sops
    claude
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
        betterdisplay
        codex
        dive
        docker
        docker-credential-helpers
        dua
        ffmpeg
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
        };

        masApps = {
          "Xcode" = 497799835;
        };

        taps = [ ];

        brews = [
          "ollama"
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
          "telegram-desktop"
          "termius"
          "visual-studio-code"
          "utm"
        ];
      };
    };
}
