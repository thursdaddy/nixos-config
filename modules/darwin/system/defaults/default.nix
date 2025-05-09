{ lib, config, ... }:
let

  inherit (lib) mkEnableOption mkIf;
  cfg = config.mine.system.defaults;

in
{
  options.mine.system.defaults = {
    enable = mkEnableOption "Enable defaults configs";
  };

  config = mkIf cfg.enable {
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
        persistent-apps = [
          (mkIf config.mine.apps.vivaldi.enable "/Applications/Vivaldi.app")
          (mkIf config.mine.apps.ghostty.enable "/Applications/Ghostty.app")
          (mkIf config.mine.apps.discord.enable "/Applications/Home Manager Apps/Discord.app")
          (mkIf config.mine.apps.element.enable "/Applications/Element.app")
          (mkIf config.mine.apps.obsidian.enable "/Applications/Obsidian.app")
          (mkIf config.mine.apps.proton.enable "/Applications/Proton Mail.app")
          (mkIf config.mine.apps.prusa-slicer.enable "/Applications/PrusaSlicer.app/")
          (mkIf config.mine.apps.steam.enable "/Applications/Steam.app")
          (mkIf config.mine.apps.aldente.enable "/Applications/AlDente.app")
          (mkIf config.mine.apps.ollama.enable "/Applications/Ollama.app")
        ];

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
