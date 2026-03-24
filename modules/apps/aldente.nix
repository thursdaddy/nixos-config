_: {
  flake.modules.darwin.apps = {
    homebrew.casks = [ "aldente" ];

    system.defaults.dock.persistent-apps = [ "/Applications/AlDente.app" ];
  };
}
