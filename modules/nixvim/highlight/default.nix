{ ... }: {
  programs.nixvim = {
    highlight = {
      Comment.fg = "#708090";
      Comment.bg = "none";
      Comment.bold = true;

      Normal.bg = "none";
      Normal.ctermbg = "none";
      NonText.bg = "none";
      NonText.ctermbg = "none";
      NonText.fg = "#48494B";
      SpecialKey.fg = "#48494B";
      NvimTreeNormal.ctermbg = "none";
      NvimTreeNormal.bg = "none";
      NormalFloat.bg = "none";
      NormalFloat.ctermbg = "none";
      LineNr.bg = "none";
    };
  };
}
