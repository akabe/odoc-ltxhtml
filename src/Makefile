SRC = \
	ltxhtml_ltximage.mli \
	ltxhtml_ltximage.ml \
	ltxhtml.ml

.PHONY: all clean

all:
	ocamlc -I +ocamldoc -o ltxhtml.cma -a $(SRC)

clean:
	rm -rf *.cmi *.cmo *.cma
