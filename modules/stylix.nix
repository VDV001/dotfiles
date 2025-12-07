{
  nixosModule =
    { pkgs, ... }:
    let
      opacity = 0.95;
      fontSize = 12;
    in
    {
      stylix = {
        enable = true;

        polarity = "dark";

        base16Scheme = {
          system = "base16";
          name = "selenized-black";
          author = "Jan Warchol (https://github.com/jan-warchol/selenized) / adapted to base16 by ali";
          variant = "dark";

          palette = {
            base00 = "181818";
            base01 = "252525";
            base02 = "3b3b3b";
            base03 = "777777";
            base04 = "777777";
            base05 = "b9b9b9";
            base06 = "dedede";
            base07 = "dedede";
            base08 = "ed4a46";
            base09 = "e67f43";
            base0A = "dbb32d";
            base0B = "70b433";
            base0C = "3fc5b7";
            base0D = "368aeb";
            base0E = "a580e2";
            base0F = "eb6eb7";
          };
        };

        opacity = {
          terminal = opacity;
          popups = opacity;
        };

        fonts = {
          serif = {
            package = pkgs.inter;
            name = "Inter";
          };

          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };

          monospace = {
            package = pkgs.jetbrains-mono;
            name = "JetBrains Mono";
          };

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };

          sizes = {
            applications = 11;
            desktop = fontSize;
            popups = fontSize;
            terminal = 11.5;
          };
        };
      };
    };

  darwinModule =
    { pkgs, ... }:
    let
      opacity = 0.95;
      fontSize = 12;
    in
    {
      stylix = {
        enable = true;

        polarity = "dark";

        base16Scheme = {
          system = "base16";
          name = "selenized-black";
          author = "Jan Warchol (https://github.com/jan-warchol/selenized) / adapted to base16 by ali";
          variant = "dark";

          palette = {
            base00 = "181818";
            base01 = "252525";
            base02 = "3b3b3b";
            base03 = "777777";
            base04 = "777777";
            base05 = "b9b9b9";
            base06 = "dedede";
            base07 = "dedede";
            base08 = "ed4a46";
            base09 = "e67f43";
            base0A = "dbb32d";
            base0B = "70b433";
            base0C = "3fc5b7";
            base0D = "368aeb";
            base0E = "a580e2";
            base0F = "eb6eb7";
          };
        };

        opacity = {
          terminal = opacity;
          popups = opacity;
        };

        fonts = {
          serif = {
            package = pkgs.inter;
            name = "Inter";
          };

          sansSerif = {
            package = pkgs.inter;
            name = "Inter";
          };

          monospace = {
            package = pkgs.jetbrains-mono;
            name = "JetBrains Mono";
          };

          emoji = {
            package = pkgs.noto-fonts-color-emoji;
            name = "Noto Color Emoji";
          };

          sizes = {
            applications = 11;
            desktop = fontSize;
            popups = fontSize;
            terminal = 11.5;
          };
        };
      };
    };
}
