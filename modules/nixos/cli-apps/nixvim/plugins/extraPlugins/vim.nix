{ pkgs, ... }: {
  programs.nixvim = {
      extraPlugins = with pkgs.vimPlugins; [

        { plugin = comment-nvim; config = "lua require(\"Comment\").setup()";}

      ];
  };

}
