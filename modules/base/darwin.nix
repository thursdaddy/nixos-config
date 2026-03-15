_: {
  flake.modules.darwin.base =
    { lib, config, ... }:
    {
      system.keyboard = {
        enableKeyMapping = true;
        remapCapsLockToControl = true;
      };

      system.defaults = {
        CustomUserPreferences = {
          "com.apple.desktopservices" = {
            # Avoid creating .DS_Store files on network or USB volumes
            DSDontWriteNetworkStores = true;
            DSDontWriteUSBStores = true;
          };
          "com.apple.SoftwareUpdate" = {
            AutomaticCheckEnabled = true;
            # Check for software updates daily, not just once per week
            ScheduleFrequency = 1;
            # Download newly available updates in background
            AutomaticDownload = 1;
            # Install System data files & security updates
            CriticalUpdateInstall = 1;
          };
        };

        dock = {
          autohide = true;
          autohide-delay = 0.24;
          autohide-time-modifier = 0.5;

          largesize = 24;
          magnification = true;
          mineffect = "scale";
          minimize-to-application = true;
          mru-spaces = false;
          orientation = "bottom";
          showhidden = true;
          tilesize = 48;

          wvous-br-corner = 13;
        };

        finder = {
          AppleShowAllExtensions = true;
          AppleShowAllFiles = true;
          CreateDesktop = false;
          FXPreferredViewStyle = "Nlsv";
          FXRemoveOldTrashItems = true;
          ShowExternalHardDrivesOnDesktop = false;
          ShowPathbar = true;
          ShowStatusBar = true;
        };

        menuExtraClock = {
          FlashDateSeparators = false;
          ShowAMPM = true;
          ShowDate = 1;
          ShowDayOfMonth = true;
          ShowDayOfWeek = true;
          ShowSeconds = true;
        };

        screencapture = {
          location = "~/Pictures/ScreenShots/";
        };
      };
    };
}
