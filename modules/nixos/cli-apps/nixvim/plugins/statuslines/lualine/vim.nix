{ ... }: {

  programs.nixvim = {
    plugins = {
      lualine = {
        enable = true;
        theme = "onedark";
        sections = {
          lualine_c = [ "filename" ];
        };
      };
    };
  };

}
