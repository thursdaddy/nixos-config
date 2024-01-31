ISO_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

build:
	docker build -t $$(whoami)/nixbuild .

run:
	docker run -it -v ${ISO_DIR}/isos:/iso $$(whoami)/nixbuild ./build.sh rpi4

