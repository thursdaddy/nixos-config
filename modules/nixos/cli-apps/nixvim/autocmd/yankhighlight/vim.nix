{ ... }: {

  programs.nixvim = {
    autoGroups = {
        highlight_yank = { };
    };

    autoCmd = [
    {
     group = "highlight_yank";
     event = "TextYankPost";
     pattern = "*";
     callback = { __raw = "function() vim.highlight.on_yank { higroup = 'IncSearch', timeout = 500 } end"; };
    }
    ];
  };

}
