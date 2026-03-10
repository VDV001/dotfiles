{
  homeModule =
    { config, lib, ... }:

    {
      programs.helix = {
        enable = true;
        settings = {
          editor = {
            line-number = "relative";
            cursorline = true;
            color-modes = true;
            bufferline = "multiple";
            cursor-shape = {
              insert = "bar";
              normal = "block";
              select = "underline";
            };
            indent-guides.render = true;
            file-picker.hidden = false;
            lsp = {
              display-messages = true;
              display-inlay-hints = true;
            };
          };

          keys.normal = lib.mkMerge [
            (lib.mkIf config.programs.yazi.enable {
              "C-e" = [
                ":sh rm -f /tmp/hx-yazi-chooser"
                ":insert-output yazi %{buffer_name} --chooser-file=/tmp/hx-yazi-chooser"
                '':sh printf '\x1b[?1049h\x1b[?2004h' > /dev/tty''
                ":open %sh{cat /tmp/hx-yazi-chooser 2>/dev/null}"
                ":redraw"
              ];
            })
            (lib.mkIf config.programs.lazygit.enable {
              "C-g" = [
                ":write-all"
                ":new"
                ":insert-output lazygit"
                ":buffer-close!"
                ":redraw"
                ":reload-all"
              ];
            })
          ];
        };
      };

    };
}
