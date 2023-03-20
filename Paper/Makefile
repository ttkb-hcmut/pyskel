.PHONY: clean all dist

all:
	latexmk -pdf -shell-escape paper.tex

clean:
	latexmk -C

dist: clean
	zip eptcsstyle.zip paper.bib eptcs.cls *.bst paper.tex
