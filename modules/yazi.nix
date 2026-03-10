{
  homeModule =
    { config, lib, ... }:

    {
      programs.yazi = {
        enable = true;
        settings = {
          mgr = {
            show_hidden = true;
            sort_dir_first = true;
          };
          opener = lib.mkIf config.programs.helix.enable {
            edit = [
              {
                run = ''hx "%s"'';
                block = true;
                desc = "Open in Helix";
              }
            ];
          };
          open.prepend_rules = lib.mkIf config.programs.helix.enable [
            {
              url = "*.{rs,go,nix,toml,yaml,yml,json,js,ts,py,lua,sh,md,txt}";
              use = "edit";
            }
          ];
        };
      };
    };
}
