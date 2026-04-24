{
  homeModule =
    { pkgs, ... }:

    {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
        package = pkgs.direnv.overrideAttrs (old: {
          doCheck = false;
          env = (old.env or { }) // { CGO_ENABLED = "1"; };
        });
      };
    };
}
