{ pkgs, ... }:

{
  programs.go = {
    enable = true;
  };

  #home.sessionPath = [
  #  "$HOME/go/bin"
  #];

  home.packages = with pkgs; [
      golangci-lint
      go-migrate
      gosec
  ];
}
