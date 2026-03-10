{
  homeModule =
    { pkgs, ... }:
    let
      kotlin-lsp =
        let
          version = "261.13587.0";
          sources = {
            aarch64-darwin = {
              url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-mac-aarch64.vsix";
              sha256 = "1bcr3z5ns7l1yfb5fipj5sdchl6xg26g69070nwjc4vxh9y865ry";
            };
            x86_64-linux = {
              url = "https://download-cdn.jetbrains.com/kotlin-lsp/${version}/kotlin-lsp-${version}-linux-x64.vsix";
              sha256 = "1g2ziy3xnf2pbb6dsi8c5rg8pbri8j5my4ayd3fmp3b7mn12q13b";
            };
          };
          src =
            sources.${pkgs.stdenv.hostPlatform.system}
              or (throw "Unsupported platform: ${pkgs.stdenv.hostPlatform.system}");
        in
        pkgs.vscode-utils.buildVscodeExtension {
          pname = "kotlin-lsp";
          inherit version;
          vscodeExtName = "kotlin-lsp";
          vscodeExtUniqueId = "kotlin.kotlin-lsp";
          vscodeExtPublisher = "kotlin";

          src = pkgs.fetchurl {
            inherit (src) url sha256;
          };

          nativeBuildInputs = [ pkgs.unzip ];

          unpackPhase = ''
            runHook preUnpack
            unzip "$src"
            runHook postUnpack
          '';
        };
    in
    {
      programs.vscode = {
        enable = true;
        profiles = {
          default = {
            enableUpdateCheck = false;
            enableExtensionUpdateCheck = false;

            extensions =
              with pkgs.nix-vscode-extensions.vscode-marketplace;
              [
                ms-vscode-remote.remote-containers
                ms-azuretools.vscode-containers
                eamodio.gitlens
                vscodevim.vim
                alefragnani.project-manager
                ms-kubernetes-tools.vscode-kubernetes-tools
                github.vscode-pull-request-github
                github.copilot-chat
                humao.rest-client

                sonarsource.sonarlint-vscode
                streetsidesoftware.code-spell-checker
                streetsidesoftware.code-spell-checker-russian
                usernamehw.errorlens

                chrmarti.regex

                redhat.vscode-yaml
                redhat.vscode-xml
                mechatroner.rainbow-csv
                janisdd.vscode-edit-csv

                jnoortheen.nix-ide

                ms-python.python
                ms-python.debugpy
                ms-python.pylint
                ms-python.vscode-pylance
                ms-toolsai.jupyter

                oracle.oracle-java
                vscjava.vscode-java-debug
                vscjava.vscode-gradle
                vscjava.vscode-maven
                vscjava.vscode-java-test
                vscjava.vscode-java-dependency
                redhat.java

                golang.go

                rust-lang.rust-analyzer

                haskell.haskell
                jakebecker.elixir-ls
                gleam.gleam

                dbaeumer.vscode-eslint
                esbenp.prettier-vscode
                formulahendry.auto-close-tag
                pranaygp.vscode-css-peek
                vitest.explorer
                svelte.svelte-vscode
                vue.volar
              ]
              ++ [
                kotlin-lsp
              ];

            userSettings = {
              "files.autoSave" = "afterDelay";
              "editor.minimap.enabled" = false;
              "window.density.editorTabHeight" = "compact";
              "editor.unicodeHighlight.allowedLocales"."ru" = true;
              "cSpell.language" = "en,ru";

              "editor.fontLigatures" = true;
              "editor.lineHeight" = 1.6;

              "editor.formatOnSave" = true;
              "editor.formatOnPaste" = true;

              # IntelliSense
              "editor.inlayHints.enabled" = "on";
              "editor.semanticHighlighting.enabled" = true;
              "editor.suggestSelection" = "recentlyUsedByPrefix";
              "editor.acceptSuggestionOnEnter" = "smart";

              # Brackets & guides
              "editor.bracketPairColorization.enabled" = true;
              "editor.guides.bracketPairs" = "active";

              # Navigation
              "editor.stickyScroll.enabled" = true;
              "explorer.compactFolders" = false;

              "python.analysis.typeCheckingMode" = "standard";

              "jdk.telemetry.enabled" = false;
              "java.completion.importOrder" = [
                "java"
                "javax"
                "org"
                "com"
                ""
              ];
              "editor.codeActionsOnSave"."source.organizeImports" = true;
              "java.configuration.updateBuildConfiguration" = "automatic";
            };
          };
        };
      };
    };
}
