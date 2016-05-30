targets = informe.pdf

includes = secciones/ej1.tex secciones/ej2.tex secciones/ej3.tex \
	   secciones/ej4.tex secciones/ej5.tex secciones/ej6.tex \
	   secciones/ej7.tex
libs = caratula.sty

all: $(targets)

$(targets) : %.pdf : %.tex $(libs) $(includes)
	pdflatex $*
	pdflatex $*

clean:
	@rm $(targets) 2>/dev/null || true
	@rm ./*.aux 2>/dev/null || true
	@rm ./*.log 2>/dev/null || true
	@rm ./*.out 2>/dev/null || true
	@rm ./*.toc 2>/dev/null || true

