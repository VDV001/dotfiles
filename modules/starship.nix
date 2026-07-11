{
  homeModule =
    { lib, pkgs, ... }:

    let
      os = icon: fg: "[${icon} ](fg:${fg})";

      lang = icon: color: {
        symbol = icon;
        format = "[$symbol ](${color})";
      };

      pad = {
        left = "";
        right = "";
      };
    in
    {
      home.packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.droid-sans-mono
        nerd-fonts.noto
        nerd-fonts.hack
      ];

      programs.starship = {
        enable = true;

        settings = {
          add_newline = false;
          format = lib.concatStrings [
            "$nix_shell"
            "\${custom.claude_profile}"
            "$os"
            "$directory"
            "$shlvl"
            "$shell"
            "$username"
            "$hostname"
            "$direnv"
            "$git_branch"
            "$git_commit"
            "$git_state"
            "$git_stage"
            "$git_status"
            "$git_metrics"
            "$package"
            "$docker_context"
            "$kubernetes"
            "$aws"
            "$gcloud"
            "$python"
            "$nodejs"
            "$bun"
            "$deno"
            "$lua"
            "$rust"
            "$java"
            "$c"
            "$golang"
            "$dart"
            "$elixir"
            "$jobs"
            "$status"
            "$cmd_duration"
            "$line_break"
            "$character"
            "\${custom.space}"
          ];
          # Правый край промпта: время запуска команды + заряд батареи
          right_format = lib.concatStrings [
            "$time"
            "$battery"
          ];
          scan_timeout = 10;
          nix_shell = {
            disabled = false;
            heuristic = true;
            format = "[${pad.left}](fg:white)[ ](bg:white fg:black)[${pad.right}](fg:white) ";
          };
          custom.space = {
            when = "! test $env";
            format = "  ";
          };
          # Активный Claude-профиль (work/personal). Показывается только когда
          # CLAUDE_CONFIG_DIR экспортирован в шелл (алиасы claude-work/-personal
          # задают его лишь для процесса claude, так что в обычном промпте пусто).
          custom.claude_profile = {
            when = ''[ -n "$CLAUDE_CONFIG_DIR" ]'';
            command = ''basename "$CLAUDE_CONFIG_DIR" | sed 's/^\.claude-//' '';
            format = "[ $output ](fg:bright-magenta)";
          };
          status = {
            disabled = false;
            symbol = "✗";
            not_found_symbol = "󰍉 Not Found";
            not_executable_symbol = " Can't Execute E";
            sigint_symbol = "󰂭 ";
            signal_symbol = "󱑽 ";
            success_symbol = "";
            format = "[ $symbol$common_meaning$signal_name$maybe_int](fg:red)";
            map_symbol = true;
          };
          os = {
            disabled = false;
            format = "$symbol";
            symbols = {
              Arch = os "" "bright-blue";
              Alpine = os "" "bright-blue";
              Debian = os "" "red";
              EndeavourOS = os "" "purple";
              Fedora = os "" "blue";
              NixOS = os "" "blue";
              openSUSE = os "" "green";
              SUSE = os "" "green";
              Ubuntu = os "" "bright-purple";
              Macos = os "" "white";
            };
          };
          directory = {
            #format = " [${pad.left}](fg:bright-black)[$path](bg:bright-black fg:white)[${pad.right}](fg:bright-black)";
            truncation_length = 6;
            truncation_symbol = "~/󰇘/";
          };
          git_branch = {
            symbol = "";
            style = "";
            format = "[ $symbol $branch](fg:purple)(:$remote_branch)";
          };
          # Состояние незавершённой операции: REBASING 2/5, MERGING, CHERRY-PICKING
          git_state = {
            format = "[ $state( $progress_current/$progress_total)](fg:bright-red)";
          };
          # Масштаб дифа: +добавлено / -удалено строк
          git_metrics = {
            disabled = false;
            format = "[ +$added](fg:green)[-$deleted](fg:red)";
          };
          # Версия проекта из package.json / Cargo.toml / go.mod и т.п.
          package = {
            symbol = "󰏗 ";
            format = "[ $symbol$version](fg:208)";
          };
          # direnv активен (nix-shell / devenv) — просто иконка
          direnv = {
            disabled = false;
            symbol = "󱁿 ";
            format = "[ $symbol]($style)";
            style = "fg:bright-yellow";
          };
          # Docker-контекст (когда не default / рядом с docker-файлами)
          docker_context = {
            symbol = "󰡨 ";
            format = "[ $symbol$context]($style)";
            style = "fg:blue";
          };
          # Kubernetes: контекст · namespace (в директориях с k8s-файлами)
          kubernetes = {
            disabled = false;
            symbol = "⎈ ";
            format = "[ $symbol$context( · $namespace)]($style)";
            style = "fg:cyan";
          };
          # AWS: профиль · регион (когда задан AWS_PROFILE/креды)
          aws = {
            symbol = "󰸏 ";
            format = "[ $symbol$profile( · $region)]($style)";
            style = "fg:208";
          };
          # GCloud: аккаунт · проект (когда есть активная конфигурация)
          gcloud = {
            symbol = "󱇶 ";
            format = "[ $symbol$account( · $project)]($style)";
            style = "fg:blue";
          };
          # Время запуска команды (правый край)
          time = {
            disabled = false;
            time_format = "%R";
            format = "[ $time](fg:bright-black)";
          };
          # Заряд батареи с цветом-порогом (правый край)
          battery = {
            full_symbol = "󰁹 ";
            charging_symbol = "󰂄 ";
            discharging_symbol = "󰁿 ";
            unknown_symbol = "󰁽 ";
            empty_symbol = "󰂎 ";
            format = "[ $symbol$percentage]($style)";
            display = [
              {
                threshold = 20;
                style = "fg:red";
              }
              {
                threshold = 50;
                style = "fg:yellow";
              }
              {
                threshold = 100;
                style = "fg:green";
              }
            ];
          };
          continuation_prompt = "∙  ┆ ";
          line_break = {
            disabled = false;
          };
          cmd_duration = {
            min_time = 1000;
            format = "[$duration ](fg:yellow)";
          };

          python = lang "" "yellow";
          nodejs = lang "󰛦" "bright-blue";
          bun = lang "󰛦" "blue";
          deno = lang "󰛦" "blue";
          lua = lang "󰢱" "blue";
          rust = lang "" "red";
          java = lang "" "red";
          c = lang "" "blue";
          golang = lang "" "blue";
          dart = lang "" "blue";
          elixir = lang "" "purple";

          character = {
            success_symbol = "[›](bold green)";
            error_symbol = "[›](bold red)";
          };
        };
      };
    };
}
