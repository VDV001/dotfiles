{
  homeModule =
    {
      pkgs,
      lib,
      username,
      useremail,
      ...
    }:
    {
      home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
        rm -f ~/.gitconfig
      '';

      home.packages = [ pkgs.git-absorb ];

      programs.git = {
        enable = true;
        lfs.enable = true;

        ignores = [
          ".claude/"
          ".claude-flow/"
          ".swarm/"
        ];

        settings = {
          user = {
            name = username;
            email = useremail;
          };

          init.defaultBranch = "main";
          push.autoSetupRemote = true;
          push.rebase = true;
          pull.rebase = false;

          branch.sort = "-committerdate";
          fetch.prune = true;
          diff.algorithm = "histogram";
          merge.conflictstyle = "zdiff3";
          rerere.enabled = true;

          alias = {
            ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
            ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";

            # aliases for submodule
            update = "submodule update --init --recursive";
            foreach = "submodule foreach";
          };
        };
      };

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          features = "side-by-side";
        };
      };
    };
}
