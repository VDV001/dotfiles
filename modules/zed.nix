{
  homeModule =
    { config, ... }:

    {
      programs.zed-editor = {
        enable = true;
        # Бинарь Zed берём готовым из Homebrew-cask "zed", а не собираем из nixpkgs:
        # для aarch64-darwin zed-editor нет в бинарном кэше -> компиляция из исходников ~2ч.
        # package = null отключает сборку/установку пакета, но настройки, расширения и
        # keymaps ниже остаются декларативными (HM пишет ~/.config/zed/*, cask-бинарь их читает).
        package = null;
        extensions = [
          "catppuccin"

          "dockerfile"
          "docker-compose"
          "git-firefly"
          "helm"
          "nix"
          "java"
          "kotlin"
          "html"
          "sql"
          "svelte"
          "vue"
          "toml"
          "golangci-lint"
          "justfile"
          "make"
          "haskell"
          "elixir"
          "gleam"
          "proto"

          # MCP
          "mcp-server-context7"
        ];
        userSettings = {
          theme = {
            mode = "system";
            light = "Ayu Light";
            dark = "Catppuccin Mocha";
          };
          icon_theme = "Material Icon Theme";
          telemetry = {
            metrics = false;
          };
          vim_mode = true;
          autosave = "on_focus_change";
          file_types = {
            Helm = [
              "**/templates/**/*.tpl"
              "**/templates/**/*.yaml"
              "**/templates/**/*.yml"
              "**/helmfile.d/**/*.yaml"
              "**/helmfile.d/**/*.yml"
              "**/values*.yaml"
            ];
          };
          lsp = {
            rust-analyzer = {
              binary = {
                path = "/run/current-system/sw/bin/rust-analyzer";
              };
            };
          };
        };
      };
    };
}
