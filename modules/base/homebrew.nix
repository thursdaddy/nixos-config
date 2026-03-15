_: {
  flake.modules.darwin.base = {
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        upgrade = true;
      };
    };
  };
}
