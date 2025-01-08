_: {
  programs.nixvim = {
    highlight = {
      PMenu.bg = "none";
      IncSearch.fg = "#ffffff";
      IncSearch.bg = "#d65d0e";
      SpecialKey.fg = "#d65d0e";
      Normal.bg = "none";
      SignColumn.ctermbg = "none";
      DiagnosticSignError = {
        ctermbg = "none";
        fg = "#fb4934"; #Red
        bold = true;
      };
      DiagnosticSignWarn = {
        bold = true;
        ctermbg = "none";
        fg = "#fe8019"; #Orange
      };
      DiagnosticSignInfo = {
        bold = true;
        ctermbg = "none";
        fg = "#83a598"; #Blue
      };
      DiagnosticSignHint = {
        bold = true;
        ctermbg = "none";
        fg = "#8ec07c"; #Aqua
      };
    };
  };
}
