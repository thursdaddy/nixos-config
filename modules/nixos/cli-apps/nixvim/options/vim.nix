{ ... }: {

 programs.nixvim = {
   options = {
     shiftwidth = 2;
     number = true;
     relativenumber = true;
   };

   highlight = {
    Comment.fg = "#708090";
    Comment.bg = "none";
    Comment.bold = true;
   };
 };

}

