{ lib, config, ... }:
with lib;
with lib.thurs;
let
  cfg = config.mine.system;
in
{
  options.mine.system = {
    ami = mkEnableOption "Enable ami build options";
  };

  config = mkIf cfg.ami {
    ec2.hvm = true;
  };
}
