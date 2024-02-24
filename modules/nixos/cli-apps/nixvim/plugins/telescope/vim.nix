{ ... }: {

  programs.nixvim = {
     plugins = {
       telescope = {
         enable = true;
         highlightTheme = "ivy";
         defaults = { ## these dont seem to be working but arent breaking anything
           layout_strategy = "horizontal";
           layout_config = {
             height = 0.85;
             width = 0.75;
             prompt_position = "bottom";
           };
         };
         keymaps = {
           "<leader>ff" = "find_files";
           "<leader>fb" = "buffers";
           "<leader>fs" = "grep_string";
           "<leader>fh" = "oldfiles";
           "<C-f>" = "live_grep";

           "<leader>fg" = "git_files";
           "<leader>fgb" = "git_branches";
           "<leader>fgs" = "git_stash";
           "<leader>fgc" = "git_commits";
           "<leader>fbc" = "git_bcommits";
         };
       };
     };
  };

}
