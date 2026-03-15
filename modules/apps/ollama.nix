_: {
  flake.modules.darwin.apps = {
    homebrew.casks = [ "ollama-app" ];

    system.defaults.dock.persistent-apps = [ "/Applications/Ollama.app" ];
  };
}
