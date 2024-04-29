{ ... }: {
  programs.nixvim = {
    highlight = {
      PMenu.bg = "none";
      IncSearch.fg = "#ffffff";
      IncSearch.bg = "#d65d0e";
      SpecialKey.fg = "#d65d0e";
      Normal.bg = "none";
      SignColumn.ctermbg = "none";
      DiagnosticSignError.ctermbg = "none";
      DiagnosticSignWarn.ctermbg = "none";
      DiagnosticSignInfo.ctermbg = "none";
      DiagnosticSignHint.ctermbg = "none";
      DiagnosticSignError.fg = "#fb4934"; #Red
      DiagnosticSignWarn.fg = "#fe8019"; #Orange
      DiagnosticSignInfo.fg = "#83a598"; #Blue
      DiagnosticSignHint.fg = "#8ec07c"; #Aqua
      DiagnosticSignError.bold = true;
      DiagnosticSignWarn.bold = true;
      DiagnosticSignInfo.bold = true;
      DiagnosticSignHint.bold = true;
    };
  };
}
