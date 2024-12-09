host := ```
   echo $(hostname)
```

rebuild:
  ./nix.sh rebuild {{host}}

build target:
  ./nix.sh build {{target}}

local input:
  ./nix.sh local {{input}}

update input:
  ./nix.sh update {{input}}

c137:
  ./nix.sh rebuild c137

cloudbox:
  ./nix.sh rebuild cloudbox

workbox:
  ./nix.sh rebuild workbox

printpi:
  ./nix.sh rebuild printpi

mbp:
  ./nix.sh rebuild mbp

netpi1:
  ./nix.sh rebuild netpi1

netpi2:
  ./nix.sh rebuild netpi2

piholes:
  ./nix.sh rebuild netpi1
  ./nix.sh rebuild netpi2
  ./nix.sh rebuild printpi

