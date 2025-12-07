{
  homeModule =
    { pkgs, ... }:

    {
      programs.go = {
        enable = true;
      };

      home.sessionPath = [
        "$HOME/go/bin"
      ];

      home.packages = with pkgs; [
        delve
        golangci-lint
        gopls
        gosec
        sqlc
        go-migrate
      ];
    };
}
