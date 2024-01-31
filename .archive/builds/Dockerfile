FROM nixos/nix

WORKDIR /build

COPY flake.nix /build
COPY iso.nix /build
COPY build.sh /build

RUN nix-channel --add https://nixos.org/channels/nixos-22.05 nixpkgs &&\
    nix-channel --update &&\
    nix-env -iA nixpkgs.gawk &&\
    echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
