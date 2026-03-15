_: {
  flake.modules.nixos.services =
    { lib, config, ... }:
    let
      cfg = config.mine.services.ollama;
    in
    {
      options.mine.services.ollama = {
        enable = lib.mkEnableOption "Enable Ollama";
      };

      config = lib.mkIf cfg.enable {
        services.ollama = {
          enable = true;
          host = "0.0.0.0";
          port = 11434;
          acceleration = "rocm";
        };

        networking.firewall.allowedTCPPorts = [ 11434 ];
      };
    };
}
