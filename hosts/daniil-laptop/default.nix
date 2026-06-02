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
          "TestFlight" = 899247664;
          "Xcode" = 497799835;
        };

        taps = [ ];

        brews = [
          "ollama"
          "vercel-cli"
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
          "utm"
        ];
      };
    };
}
