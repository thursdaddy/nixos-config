{ lib, ... }:

# Credit: @JakeHamilton
# https://github.com/jakehamilton/config/blob/bf8411ec6b636f887dac45970864e09ba3ebf816/lib/module/default.nix

with lib;
{
  ## Create a NixOS module option.
  ##
  ## ```nix
  ## lib.mkOpt nixpkgs.lib.types.str "My default" "Description of my option."
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt =
    type: default: description:
    mkOption { inherit type default description; };

  ## Create a NixOS module option without a description.
  ##
  ## ```nix
  ## lib.mkOpt' nixpkgs.lib.types.str "My default"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt' = type: default: mkOpt type default null;

  ## Create a NixOS module option with no default
  ##
  ## ```nix
  ## lib.mkOpt_ types.path "Description of my option"
  ## ```
  ##
  #@ Type -> Any -> String
  mkOpt_ = type: description: mkOption { inherit type description; };

  enabled = {
    ## Quickly enable an option.
    ##
    ## ```nix
    ## services.nginx = enabled;
    ## ```
    ##
    #@ true
    enable = true;
  };

  disabled = {
    ## Quickly disable an option.
    ##
    ## ```nix
    ## services.nginx = disabled;
    ## ```
    ##
    #@ false
    enable = false;
  };
}
