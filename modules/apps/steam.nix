_: {
  flake.modules.darwin.apps = {
    homebrew = {
      brews = [ "docker-buildx" ];
      casks = [ "docker-desktop" ];
    };
  };
}
