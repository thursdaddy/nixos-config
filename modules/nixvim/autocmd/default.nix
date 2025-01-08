_: {
  programs.nixvim = {
    autoGroups = {
      highlight_yank = { };
      wscleanup = { };
    };

    autoCmd = [
      {
        group = "highlight_yank";
        event = "TextYankPost";
        pattern = "*";
        callback = { __raw = "function() vim.highlight.on_yank { higroup = 'IncSearch', timeout = 500 } end"; };
      }
      {
        group = "wscleanup";
        event = "BufWritePre";
        pattern = "*";
        command = "%s/\\s\\+$//e";
      }
    ];
  };
}
