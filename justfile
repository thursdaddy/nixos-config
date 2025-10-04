host := ```
   echo $(hostname)
```

statix:
  @statix check

rebuild:
  @./nix.sh rebuild {{host}}

build target:
  @./nix.sh build {{target}}
  @if [[ {{target}} == "vm-nogui" ]]; then tmux new-window -n {{target}} ./result/bin/run-nixos-vm; fi

local input:
  @./nix.sh local {{input}}

update input:
  @./nix.sh update {{input}}

c137:
  @./nix.sh rebuild c137

cloudbox:
  @./nix.sh rebuild cloudbox

homebox:
  @./nix.sh rebuild homebox

proxbox1:
  @./nix.sh rebuild proxbox1

printpi:
  @./nix.sh rebuild printpi

mbp:
  @./nix.sh rebuild mbp

netpi1:
  @./nix.sh rebuild netpi1

netpi2:
  @./nix.sh rebuild netpi2

kepler:
  @./nix.sh rebuild kepler

wormhole:
  @./nix.sh rebuild wormhole

jupiter:
  @./nix.sh rebuild jupiter

blocky:
  @./nix.sh rebuild netpi1
  @./nix.sh rebuild netpi2
  @./nix.sh rebuild homebox

all:
  @./nix.sh rebuild jupiter
  @./nix.sh rebuild wormhole
  @./nix.sh rebuild kepler
  @./nix.sh rebuild cloudbox
  @./nix.sh rebuild netpi1
  @./nix.sh rebuild netpi2
  @./nix.sh rebuild printpi
  @./nix.sh rebuild homebox
  @./nix.sh rebuild c137

help:
  @./nix.sh help

attic input:
  @./nix.sh attic {{input}}
