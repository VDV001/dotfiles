{
  homeModule =
    { pkgs, ... }:

    {
      home.packages = with pkgs; [
        (pkgs.python313.withPackages (ps: [
          ps.pip
          ps.pyyaml
          ps.pandas
          ps.requests
        ]))
      ];

      programs.uv.enable = true;
    };
}
