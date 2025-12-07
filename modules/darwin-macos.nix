{
  darwinModule =
    { username, ... }:
    {
      # https://daiderd.com/nix-darwin/manual/index.html#sec-options
      # https://github.com/yannbertrand/macos-defaults
      system = {
        defaults = {
          dock = {
            autohide = true;
            autohide-delay = 86400.0;
            autohide-time-modifier = 0.0;
            magnification = false;
            mineffect = "scale";
            show-recents = false;
            orientation = "bottom";
            tilesize = 40;
            # Hot-corners
            wvous-tl-corner = 1; # top-left
            wvous-tr-corner = 1; # top-right
            wvous-bl-corner = 1; # bottom-left
            wvous-br-corner = 1; # bottom-right
          };

          finder = {
            _FXShowPosixPathInTitle = true; # show full path in finder title
            FXDefaultSearchScope = "SCcf"; # Set search scope to directory
            AppleShowAllExtensions = true;
            AppleShowAllFiles = true;
            FXEnableExtensionChangeWarning = false;
            QuitMenuItem = true;
            ShowPathbar = true;
            ShowStatusBar = true;
            NewWindowTarget = "Home";
          };

          trackpad = {

          };

          WindowManager = {
            EnableStandardClickToShowDesktop = false;
          };

          CustomUserPreferences = {
            "com.apple.desktopservices" = {
              # Disable creating .DS_Store files in network an USB volumes
              DSDontWriteNetworkStores = true;
              DSDontWriteUSBStores = true;
            };

            "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
          };
        };

        keyboard = {
          enableKeyMapping = true;

          remapCapsLockToEscape = true;
        };
      };

      programs.zsh.enable = true;
    };
}
