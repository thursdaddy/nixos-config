#!/root/.nix-profile/bin/bash

nix build $1

case $1 in 
  iso)
	  id = $(echo $1 | awk -F'.' '{print $3}')
esac

if [ -L result ]; then
    # get /nix/store symlink path
    iso_path=$(ls -lah result | awk -F'-> ' '{ print $2 }')
    printf "\nSuccess: $iso_path\n"

    # get iso name with no .iso ending
    # to be able to add timestamp to
    # final iso name
    filename_no_iso=$(ls -lah result | awk -F'nixos' '{ sub(/.iso/, "");print "nixos"$2 }')
    timestamp=$(date +%m%d%y-%H%M)
    iso_name=$id-$filename_no_iso

    # move and rename iso file
    mv $iso_path/iso/$filename_no_iso.iso /isos/$iso_name-$timestamp.iso
    printf "\nMoved $iso_path to:\n/isos/$iso_name-$timestamp.iso\n"
else
    printf "\nSomething went wrong...\n¯/\_(ツ)_/¯\n"
fi

