all:
	pdflatex -shell-escape quark
	pdflatex -shell-escape quark
	bibtex quark
	bibtex quark
	pdflatex -shell-escape quark
	bibtex quark
	pdflatex -shell-escape quark

haste:
	pdflatex -shell-escape quark
	open quark.pdf

clean:
	rm *.aux *.bbl *.out *.log
