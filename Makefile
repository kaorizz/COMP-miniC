a.out: lex.yy.c miniC.tab.h miniC.tab.c listaSimbolos.h listaSimbolos.c listaCodigo.c listaCodigo.h main.c

	gcc lex.yy.c miniC.tab.c listaSimbolos.c listaCodigo.c main.c -lfl -o a.out


miniC.tab.c miniC.tab.h: miniC.y

	bison -d miniC.y
	

lex.yy.c: miniC.l miniC.tab.h

	flex miniC.l

clear: lex.yy.c miniC.tab.c miniC.tab.h a.out
	rm lex.yy.c miniC.tab.c miniC.tab.h a.out
