_: {
  flake.modules.nixos.desktop =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.mine.desktop.cursor;

      adwaita-hyprcursor = pkgs.stdenv.mkDerivation {
        name = "adwaita-hyprcursor";
        src = pkgs.fetchFromGitHub {
          owner = "joaoalves03";
          repo = "adwaita-hyprcursor";
          rev = "3fc6c5435b75c104cf6a156960900506af622ab4";
          sha256 = "sha256-4DQvZVXarkyNvLKCxP+j3VVG3+BjxcOno5NHRMamc5U=";
        };
        installPhase = ''
          mkdir -p $out/share/icons/adwaita-hyprcursor
          cp -r hyprcursors/* $out/share/icons/adwaita-hyprcursor/
        '';
      };

      oblique-hyprcursor = pkgs.stdenv.mkDerivation {
        name = "oblique-hyprcursor";
        src = pkgs.fetchFromGitHub {
          owner = "kayxean";
          repo = "oblique-cursor";
          rev = "ccd0dde640fc50c957dbccabf1e1c1884c7f2af4";
          version = "v1.0.0";
          sha256 = "sha256-Jf7zeT4tVXeFz3YPkGJyME3GJjAtFjMJKTQs3jNieR4=";
          # sha256 = pkgs.lib.fakeSha256;
        };
        nativeBuildInputs = [ pkgs.hyprcursor ];
        installPhase = ''
          mkdir -p $out/share/icons/oblique-cursor
          cd themes/oblique-cursor/
          hyprcursor-util --create . --output .
          ls -lah
          cp -r theme_oblique-cursor/* $out/share/icons/oblique-cursor
        '';
      };
    in
    {
      options.mine.desktop.cursor = {
        enable = lib.mkEnableOption "Enable cursor config";
      };

      config = lib.mkIf cfg.enable {
        environment.systemPackages = [
          pkgs.hyprcursor
          pkgs.adwaita-icon-theme
          adwaita-hyprcursor
          oblique-hyprcursor
        ];

        services.dbus.enable = true;

        environment.sessionVariables = {
          HYPRCURSOR_THEME = "oblique-cursor";
          HYPRCURSOR_SIZE = "30";
        };
      };
    };
}
