{ lib, ... }:
with lib;
{
  options.mine.system = {
    ami = mkEnableOption "Enable ami build";
  };

  config = mkIf cfg.ami {
    ec2.hvm = true;
  };
}
