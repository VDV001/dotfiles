{ pkgs, pkgs-master, ... }:

{
  environment.systemPackages = with pkgs; [
    age
    aria2
    betterdisplay
    codex
    claude-code
    dive
    docker
    docker-credential-helpers
    dua
    ffmpeg
    gh
    glab
    glow
    httpie
    insomnia
    just
    sops
  ];
  environment.variables.EDITOR = "nvim";

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
      "gnupg"
      "pinentry-mac"
      "ykman"
      "ollama"
    ];

    casks = [
      "claude"
      "figma"
      "gpg-suite"
      "google-chrome"
      "iina"
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
      "webstorm"
    ];
  };
}
