{ lib, ... }:
let
  inherit (lib) mkOption types;
  inherit (lib.thurs) mkOpt;
in
{
  options = {
    mine.container.configPath = mkOpt types.path "/opt/configs" "Base path for storing container configs";
  };
}
