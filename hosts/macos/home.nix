{ username, ... }:

{
  imports = [
    ../../home/bat
    ../../home/eza
    ../../home/fastfetch
    ../../home/git
    ../../home/helix
    ../../home/htop
    ../../home/k8s
    ../../home/kitty
    ../../home/lazydocker
    ../../home/lazygit
    ../../home/js
    ../../home/nushell
    ../../home/postgresql
    ../../home/proto
    ../../home/python
    ../../home/skim
    ../../home/ssh
    ../../home/starship
    ../../home/translateshell
    ../../home/yazi
    ../../home/zsh
    ../../home/go
  ];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";

    stateVersion = "25.05";
  };

  programs.home-manager.enable = true;
}
