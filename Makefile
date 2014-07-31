.PHONY: all example clean

all:
	make -C src

example: all
	make -C example

clean:
	make clean -C src
	make clean -C example
