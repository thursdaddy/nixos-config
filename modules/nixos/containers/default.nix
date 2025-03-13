{ lib, ... }:
let
  inherit (lib) types;
  inherit (lib.thurs) mkOpt;
in
{
  options = {
    mine.container.settings.configPath =
      mkOpt types.path "/opt/configs"
        "Base path for storing container configs";
  };
}
