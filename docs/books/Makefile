# Builds the SDSF manuals.  Needs typst and the bookmaster submodule
# (git submodule update --init docs/books/bookmaster).

TYPST ?= typst
BM    := bookmaster
# The PDF carries the edition: ml11-0001-0.pdf is the Draft of ML11-0001.
BOOKS := ml11-0001-0.pdf ml11-0002-0.pdf

.PHONY: all clean

all: $(BOOKS)

ml11-0001-%.pdf: ml11-0001.typ $(wildcard guide/*.typ) $(BM)/bookmaster.typ
	$(TYPST) compile --root . --font-path $(BM)/fonts --ignore-system-fonts $< $@

ml11-0002-%.pdf: ml11-0002.typ $(wildcard ref/*.typ) $(BM)/bookmaster.typ
	$(TYPST) compile --root . --font-path $(BM)/fonts --ignore-system-fonts $< $@

clean:
	rm -f *.pdf
