{ pkgs, ... }:

{
  imports = [ 
    ../../modules/darwin/system.nix
  ];

  environment.systemPackages = with pkgs; [
    aria2
    antigravity
    betterdisplay
    codex
    claude-code
    docker
    docker-credential-helpers
    gopls
    just
    lunarvim
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

    taps = [
    ];

    brews = [
      "ffmpeg"
      "gnupg"
      "pinentry-mac"
      "ykman"
      "gh"
      "ollama"
    ];

    casks = [
      "asix-ax88179"
      "figma"
      "gpg-suite"
      "google-chrome"
      "iina"
      "linearmouse"
      "logseq"
      "maccy"
      "orbstack"
      "outline-manager"
      "telegram-desktop"
      "termius"
      "visual-studio-code"
      "webstorm"
    ];
  };
}
