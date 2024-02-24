{ ... }: {
# auto cleanup whitespace when saving
  programs.nixvim = {
    autoGroups = {
        wscleanup = { };
    };

    autoCmd = [
    {
     group = "wscleanup";
     event = "BufWritePre";
     pattern = "*";
     command = "%s/\\s\\+$//e";
    }
    ];
  };

}
