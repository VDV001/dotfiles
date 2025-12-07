{
  homeModule =
    { pkgs, ... }:
    let
      kotlin-lsp = pkgs.vscode-utils.buildVscodeExtension {
        pname = "kotlin-lsp";
        version = "0.253.10629";
        vscodeExtName = "kotlin-lsp";
        vscodeExtUniqueId = "kotlin.kotlin-lsp";
        vscodeExtPublisher = "kotlin";

        src = pkgs.fetchurl {
          url = "https://download-cdn.jetbrains.com/kotlin-lsp/0.253.10629/kotlin-0.253.10629.vsix";
          sha256 = "077ibc8mkgbcb283f9spk70cb5zv7i20dpy7z1c52zny5xaw33k3";
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
                ms-kubernetes-tools.vscode-kubernetes-tools
                github.vscode-pull-request-github
                humao.rest-client

                sonarsource.sonarlint-vscode
                streetsidesoftware.code-spell-checker
                streetsidesoftware.code-spell-checker-russian

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
              "editor.density.editorTabHeight" = "compact";
              "editor.unicodeHighlight.allowedLocales" = {
                "ru" = true;
              };
              "cSpell.language" = "en,ru";

              "python.analysis.typeCheckingMode" = "standard";

              "jdk.telemetry.enabled" = false;
            };
          };
        };
      };
    };
}
