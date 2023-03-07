all: paper.pdf

%.pdf: %.tex %.bib
	pdflatex -shell-escape $*
	pdflatex -shell-escape $*
	bibtex $*
	pdflatex -shell-escape $*

clean:
	@rm -f paper.pdf *.{aux,log,bbl,out,blg,vtc}
	@rm -rf _minted-*
