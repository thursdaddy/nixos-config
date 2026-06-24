_: {
  flake.modules.nixos.services =
    {
      config,
      lib,
      ...
    }:
    let
      cfg = config.mine.services.mpd;
    in
    {
      options.mine.services.mpd = {
        enable = lib.mkEnableOption "Enable mpd service";
        musicDirectory = lib.mkOption {
          type = lib.types.str;
          default = "/mnt/music";
          description = "Directory containing music files";
        };
      };

      config = lib.mkIf cfg.enable {
        services.mpd = {
          enable = true;
          musicDirectory = cfg.musicDirectory;
          extraConfig = ''
            audio_output {
              type "httpd"
              name "MPD HTTP Stream"
              encoder "vorbis"
              port "8000"
              quality "5.0"
              format "44100:16:1"
              always_on "yes"
              tags "yes"
            }
            auto_update "yes"
          '';
          network.listenAddress = "any";
          network.port = 6600;
        };

        networking.firewall.allowedTCPPorts = [
        ];

        # Explicitly allow ONLY Tailscale to reach MPD
        networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
          6600 # MPD Control Protocol (for rmpc)
          8000 # MPD HTTP Audio Stream
        ];
      };
    };
}
