targets = informe.pdf

includes = secciones/objetivos.tex secciones/contexto.tex \
	   secciones/cropflip.tex secciones/ldr.tex secciones/sepia.tex \
	   secciones/conclusiones.tex bibliography.bib
libs = caratula.sty dibujitos.sty

all: $(targets)

$(targets) : %.pdf : %.tex $(libs) $(includes)
	pdflatex $*
	pdflatex $*
	bibtex $*
	pdflatex $*

clean:
	@rm $(targets) 2>/dev/null || true
	@rm ./*.aux 2>/dev/null || true
	@rm ./*.log 2>/dev/null || true
	@rm ./*.out 2>/dev/null || true
	@rm ./*.toc 2>/dev/null || true

