{ ... }: {
  programs.nixvim = {
    highlight = {
      PMenu.bg = "none";
      IncSearch.fg = "#ffffff";
      IncSearch.bg = "#d65d0e";
      SpecialKey.fg = "#d65d0e";
      Normal.bg = "none";
    };
  };
}
