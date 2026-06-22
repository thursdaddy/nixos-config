host := `echo $(hostname)`

# Define your machine lists as space-separated strings
hosts := "streambox wormhole kepler jupiter netpi1 netpi2 printpi homebox c137 cloudbox"
blocky_hosts := "netpi1 netpi2 homebox"

statix:
    @statix check

build target:
    @./nix.sh build {{target}}
    @if [[ {{target}} == "vm-nogui" ]]; then tmux new-window -n {{target}} ./result/bin/run-nixos-vm; fi

local input:
    @./nix.sh local {{input}}

update input:
    @./nix.sh update {{input}}

rebuild target +args="":
    #!/usr/bin/env bash
    if [ "{{target}}" == "all" ]; then
        for h in {{hosts}}; do
            ./nix.sh rebuild "$h" {{args}}
        done
    elif [ "{{target}}" == "blocky" ]; then
        for h in {{blocky_hosts}}; do
            ./nix.sh rebuild "$h" {{args}}
        done
    else
        ./nix.sh rebuild "{{target}}" {{args}}
    fi

attic input:
    #!/usr/bin/env bash
    if [ "{{input}}" == "all" ]; then
        for h in {{hosts}}; do
            ./nix.sh attic "$h"
        done
    else
        ./nix.sh attic "{{input}}"
    fi

help:
    @./nix.sh help
