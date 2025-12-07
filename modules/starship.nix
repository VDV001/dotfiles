{
  homeModule =
    { lib, ... }:

    let
      os = icon: fg: "[${icon} ](fg:${fg})";

      lang = icon: color: {
        symbol = icon;
        format = "[$symbol ](${color})";
      };

      pad = {
        left = "";
        right = "";
      };
    in
    {
      programs.starship = {
        enable = true;

        enableBashIntegration = true;
        enableZshIntegration = true;

        settings = {
          add_newline = false;
          format = lib.concatStrings [
            "$nix_shell"
            "$os"
            "$directory"
            "$shlvl"
            "$shell"
            "$username"
            "$hostname"
            "$git_branch"
            "$git_commit"
            "$git_stage"
            "$git_status"
            "$python"
            "$nodejs"
            "$lua"
            "$rust"
            "$java"
            "$c"
            "$golang"
            "$jobs"
            "$cmd_duration"
            "$line_break"
            "$character"
            ''''${custom.space}''
          ];
          scan_timeout = 10;
          nix_shell = {
            disabled = false;
            format = "[${pad.left}](fg:white)[ ](bg:white fg:black)[${pad.right}](fg:white) ";
          };
          custom.space = {
            when = ''! test $env'';
            format = "  ";
          };
          status = {
            symbol = "✗";
            not_found_symbol = "󰍉 Not Found";
            not_executable_symbol = " Can't Execute E";
            sigint_symbol = "󰂭 ";
            signal_symbol = "󱑽 ";
            success_symbol = "";
            format = "[$symbol](fg:red)";
            map_symbol = true;
            disabled = false;
          };
          os = {
            disabled = false;
            format = "$symbol";
            symbols = {
              Arch = os "" "bright-blue";
              Alpine = os "" "bright-blue";
              Debian = os "" "red)";
              EndeavourOS = os "" "purple";
              Fedora = os "" "blue";
              NixOS = os "" "blue";
              openSUSE = os "" "green";
              SUSE = os "" "green";
              Ubuntu = os "" "bright-purple";
              Macos = os "" "white";
            };
          };
          directory = {
            #format = " [${pad.left}](fg:bright-black)[$path](bg:bright-black fg:white)[${pad.right}](fg:bright-black)";
            truncation_length = 6;
            truncation_symbol = "~/󰇘/";
          };
          git_branch = {
            symbol = "";
            style = "";
            format = "[ $symbol $branch](fg:purple)(:$remote_branch)";
          };
          continuation_prompt = "∙  ┆ ";
          line_break = {
            disabled = false;
          };
          cmd_duration = {
            min_time = 1000;
            format = "[$duration ](fg:yellow)";
          };

          python = lang "" "yellow";
          nodejs = lang "󰛦" "bright-blue";
          bun = lang "󰛦" "blue";
          deno = lang "󰛦" "blue";
          lua = lang "󰢱" "blue";
          rust = lang "" "red";
          java = lang "" "red";
          c = lang "" "blue";
          golang = lang "" "blue";
          dart = lang "" "blue";
          elixir = lang "" "purple";

          character = {
            success_symbol = "[›](bold green)";
            error_symbol = "[›](bold red)";
          };
        };
      };
    };
}
