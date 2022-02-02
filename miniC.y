%{
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "miniC.tab.h"
#include "listaSimbolos.h"
#include "listaCodigo.h"
Lista tablaSimb;
Tipo tipo;
int contCadenas, esintacticos, esemanticos = 0;
int registros[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int contadorEtiquetas = 1;
bool esConstante(char *c);
bool perteneceTablaS(char *c);
void imprimirTablaS();
void anadeEntrada(char *c, Tipo t);
char* obtenerReg();
void liberarReg(char *a);
void imprimirCodigo(ListaC codigo);
char *concatena_(char *identificador, char *a);
char *obtenerEtiqueta();
void yyerror();
extern int yylex();
extern int yylineno;
extern char *yytext;
extern int elexicos;
%}

%union {
char *lexema;
ListaC codigo;
}

%code requires {
	#include "listaCodigo.h"
}

%type <codigo> expression statement statement_list print_item print_list read_list declarations identifier_list asig

%token VOID VAR CONST IF ELSE WHILE PRINT READ LPAREN RPAREN LKEY RKEY SEMICOLON COMMA EQUALOP PLUSOP MINUSOP ASTERISKOP SLASHOP MINUSOP2
%token <lexema> ID
%token <lexema> NUM
%token <lexema> STRING

%left PLUSOP MINUSOP
%left ASTERISKOP SLASHOP
%left MINUSOP2
%expect 1

%%
program: VOID ID LPAREN RPAREN LKEY { tablaSimb=creaLS(); } declarations statement_list RKEY { imprimirTablaS(); concatenaLC($7,$8); imprimirCodigo($7); liberaLS(tablaSimb); liberaLC($7);} ;
declarations: declarations VAR {tipo=VARIABLE;} identifier_list SEMICOLON { $$ = $1;
																			concatenaLC($$,$4);
																			liberaLC($4);					}
		| declarations CONST {tipo=CONSTANTE;} identifier_list SEMICOLON { $$ = $1;
																			concatenaLC($$,$4);
																			liberaLC($4);					}
		| %empty { $$ = creaLC(); }
		;
identifier_list: asig { $$ = $1; }
		| identifier_list COMMA asig { $$ = $1;
										concatenaLC($$,$3);
										liberaLC($3);					}
		;
asig:		ID { if (!perteneceTablaS($1)) anadeEntrada($1,tipo);
			else { printf("Error en la linea %d : variable %s ya declarada\n", yylineno, $1); esemanticos++; } 
				$$ = creaLC();											}
		| ID EQUALOP expression { if (!perteneceTablaS($1)) anadeEntrada($1,tipo);
						else { printf("Error en la linea %d : variable %s ya declarada\n", yylineno, $1); esemanticos++; } 
						$$ = $3;
						Operacion oper;
						oper.op = "sw";
						oper.res = recuperaResLC($3);
						oper.arg1 = concatena_($1,"_");
						oper.arg2 = NULL;
						insertaLC($$,finalLC($$),oper);
						liberarReg(oper.res);												}
		;
statement_list: statement_list statement { $$ = $1;
											concatenaLC($$,$2);
											liberaLC($2);				}
		| %empty { $$ = creaLC(); }
		;
statement: ID EQUALOP expression SEMICOLON { if (!perteneceTablaS($1))
								{ printf("Error en la linea %d : variable %s no declarada\n", yylineno, $1); esemanticos++; $$ = creaLC();}
							else if (esConstante($1))
								{ printf("Error en la linea %d : variable %s es constante\n", yylineno, $1); esemanticos++; $$ = creaLC();} 
							else
								{
									$$ = $3;
									Operacion oper;
									oper.op = "sw";
									oper.res = recuperaResLC($3);
									oper.arg1 = concatena_($1,"_");
									oper.arg2 = NULL;
									insertaLC($$, finalLC($$), oper);
									liberarReg(oper.res);								}																			
							}
							

		| LKEY statement_list RKEY { $$ = $2; }
		| IF LPAREN expression RPAREN statement ELSE statement {
					$$ = $3;
					Operacion oper2;
					oper2.op = "beqz";
					oper2.res = recuperaResLC($$);
					oper2.arg1 = obtenerEtiqueta();
					oper2.arg2 = NULL;
					insertaLC($$,finalLC($$),oper2);
					concatenaLC($$,$5);
					liberaLC($5);
					Operacion oper3;
					oper3.op = "b";
					oper3.res = obtenerEtiqueta();
					oper3.arg1 = NULL;
					oper3.arg2 = NULL;
					insertaLC($$,finalLC($$),oper3);
					Operacion oper4;
					oper4.op = concatena_(":",oper2.arg1);;
					oper4.res = NULL;
					oper4.arg1 = NULL;
					oper4.arg2 = NULL;
					insertaLC($$,finalLC($$),oper4);
					concatenaLC($$,$7); 
					liberaLC($7);
					Operacion oper5;
					oper5.op = concatena_(":",oper3.res);
					oper5.res = NULL;
					oper5.arg1 = NULL;
					oper5.arg2 = NULL;
					insertaLC($$,finalLC($$),oper5);					
					}

		| IF LPAREN expression RPAREN statement {
					$$ = $3;
					Operacion oper2;
					oper2.op = "beqz";
					oper2.res = recuperaResLC($$);
					oper2.arg1 = obtenerEtiqueta();
					oper2.arg2 = NULL;
					insertaLC($$,finalLC($$),oper2);
					concatenaLC($$,$5);
					liberaLC($5);
					Operacion oper3;
					oper3.op = concatena_(":",oper2.arg1);
					oper3.res = NULL;
					oper3.arg1 = NULL;
					oper3.arg2 = NULL;
					insertaLC($$,finalLC($$),oper3);					
					}
		| WHILE LPAREN expression RPAREN statement {
					$$ = creaLC();
					Operacion oper;
					char *etiq = obtenerEtiqueta();
					oper.op = concatena_(":",etiq);
					oper.res = NULL;
					oper.arg1 = NULL;
					oper.arg2 = NULL;
					insertaLC($$,finalLC($$),oper);
					concatenaLC($$,$3);
					liberaLC($3);
					Operacion oper3;
					oper3.op = "beqz";
					oper3.res = recuperaResLC($3);
					oper3.arg1 = obtenerEtiqueta();
					oper3.arg2 = NULL;
					insertaLC($$,finalLC($$),oper3);
					concatenaLC($$,$5);
					liberaLC($5);
					Operacion oper4;
					oper4.op = "b";
					oper4.res = etiq;
					oper4.arg1 = NULL;
					oper4.arg2 = NULL;
					insertaLC($$,finalLC($$),oper4);
					Operacion oper5;
					oper5.op = concatena_(":",oper3.arg1);
					oper5.res = NULL;
					oper5.arg1 = NULL;
					oper5.arg2 = NULL;
					insertaLC($$,finalLC($$),oper5);
																}
		| PRINT print_list SEMICOLON {
					$$ = $2;
		}
		| READ read_list SEMICOLON {
					$$ = $2;
		}
		;
print_list:	print_item
		| print_list COMMA print_item {
					$$ = $1;
					concatenaLC($$,$3);
					liberaLC($3);								}
		;
print_item:	expression {
					$$ = $1;
					Operacion oper;
					oper.op = "li";
					oper.res = "$v0";
					oper.arg1 = "1";
					oper.arg2 = NULL;
					insertaLC($$,finalLC($$),oper);
					Operacion oper2;
					oper2.op = "move";
					oper2.res = "$a0";
					oper2.arg1 = recuperaResLC($1);
					oper2.arg2 = NULL;
					insertaLC($$,finalLC($$),oper2);
					Operacion oper3;
					oper3.op = "syscall";
					oper3.res = NULL;
					oper3.arg1 = NULL;
					oper3.arg2 = NULL;
					insertaLC($$,finalLC($$),oper3);
					liberarReg(oper2.arg1);				}
		| STRING { anadeEntrada($1, CADENA);
					contCadenas++; 
					$$ = creaLC();
					Operacion oper2;
					oper2.op = "la";
					oper2.res = "$a0";
					char aux[16];
					sprintf(aux, "$str%d", contCadenas);
					oper2.arg1 = strdup(aux);
					insertaLC($$,finalLC($$),oper2);
					Operacion oper;
					oper.op = "li";
					oper.res = "$v0";
					oper.arg1 = "4";
					oper.arg2 = NULL;
					insertaLC($$,finalLC($$),oper);
					guardaResLC($$,oper.res);
					Operacion oper3;
					oper3.op = "syscall";
					oper3.res = NULL;
					oper3.arg1 = NULL;
					oper3.arg2 = NULL;
					insertaLC($$,finalLC($$),oper3);
																	}
		;
read_list:	ID { if (!perteneceTablaS($1))
								{ printf("Error en la linea %d : variable %s no declarada\n", yylineno, $1); esemanticos++; $$=creaLC();}
							else if (esConstante($1))
								{ printf("Error en la linea %d : identificador %s es constante\n", yylineno, $1); esemanticos++; $$=creaLC();}
							else {
									$$ = creaLC();
									Operacion oper;
									oper.op = "li";
									oper.res = "$v0";
									oper.arg1 = "5";
									oper.arg2 = NULL;
									insertaLC($$,finalLC($$),oper);
									guardaResLC($$,oper.res);
									Operacion oper2;
									oper2.op = "syscall";
									oper2.res = NULL;
									oper2.arg1 = NULL;
									oper2.arg2 = NULL;
									insertaLC($$,finalLC($$),oper2);
									Operacion oper3;	
									oper3.op = "sw";
									oper3.res = recuperaResLC($$);
									oper3.arg1 = concatena_($1,"_");
									oper3.arg2 = NULL;
									insertaLC($$,finalLC($$),oper3);														}																									
																															}
		| read_list COMMA ID { if (!perteneceTablaS($3))
								{ printf("Error en la linea %d : variable %s no declarada\n", yylineno, $3); esemanticos++; $$=creaLC();}
							else if (esConstante($3))
								{ printf("Error en la linea %d : identificador %s es constante\n", yylineno, $3); esemanticos++; $$=creaLC();} 
							else {
									$$ = $1;
									Operacion oper;
									oper.op = "li";
									oper.res = "$v0";
									oper.arg1 = "5";
									oper.arg2 = NULL;
									insertaLC($$,finalLC($$),oper);
									Operacion oper2;
									oper2.op = "syscall";
									oper2.res = NULL;
									oper2.arg1 = NULL;
									oper2.arg2 = NULL;
									insertaLC($$,finalLC($$),oper2);
									Operacion oper3;
									oper3.op = "sw";
									oper3.res = recuperaResLC($1);
									oper3.arg1 = concatena_($3,"_");
									oper3.arg2 = NULL;
									insertaLC($$,finalLC($$),oper3);
																				}
							}
		;
expression:	expression PLUSOP expression {
						$$ = $1;
						concatenaLC($$,$3);
						Operacion oper;
						oper.op = "add";
						oper.res = recuperaResLC($1);
						oper.arg1 = recuperaResLC($1);
						oper.arg2 = recuperaResLC($3);
						insertaLC($$, finalLC($$), oper);
						liberaLC($3);
						liberarReg(oper.arg2);
				}
		| expression MINUSOP expression {
						$$ = $1;
						concatenaLC($$,$3);
						Operacion oper;
						oper.op = "sub";
						oper.res = recuperaResLC($1);
						oper.arg1 = recuperaResLC($1);
						oper.arg2 = recuperaResLC($3);
						insertaLC($$, finalLC($$), oper);
						liberaLC($3);
						liberarReg(oper.arg2);	
				}
		| expression ASTERISKOP expression {
						$$ = $1;
						concatenaLC($$,$3);
						Operacion oper;
						oper.op = "mul";
						oper.res = recuperaResLC($1);
						oper.arg1 = recuperaResLC($1);
						oper.arg2 = recuperaResLC($3);
						insertaLC($$, finalLC($$), oper);
						liberaLC($3);
						liberarReg(oper.arg2);
				}
		| expression SLASHOP expression {
						$$ = $1;
						concatenaLC($$,$3);
						Operacion oper;
						oper.op = "div";
						oper.res = recuperaResLC($1);
						oper.arg1 = recuperaResLC($1);
						oper.arg2 = recuperaResLC($3);
						insertaLC($$, finalLC($$), oper);
						liberaLC($3);
						liberarReg(oper.arg2);
		}
		| MINUSOP expression %prec MINUSOP2 {
						$$ = $2;
						Operacion oper;
						oper.op = "neg";
						oper.res = recuperaResLC($2);
						oper.arg1 = recuperaResLC($2);
						oper.arg2 = NULL;
						insertaLC($$, finalLC($$), oper);
				}
		| LPAREN expression RPAREN {
						$$ = $2;
		}
		| ID { if (!perteneceTablaS($1)) { printf("Error en la linea %d : variable %s no declarada\n", yylineno, $1); esemanticos++; $$=creaLC(); guardaResLC($$,"");} 
				else {
						$$ = creaLC();
						Operacion oper;
						oper.op = "lw";
						oper.res = obtenerReg();
						oper.arg1 = concatena_($1, "_");
						oper.arg2 = NULL;
						insertaLC($$, finalLC($$), oper);
						guardaResLC($$,oper.res);
						}
					}	
		| NUM { $$ = creaLC();
				Operacion oper;
				oper.op = "li";
				oper.res = obtenerReg();
				oper.arg1 = $1;			
				oper.arg2 = NULL;	
				insertaLC($$,finalLC($$),oper);
				guardaResLC($$,oper.res); }
		;
%%

void yyerror()
{
	printf("Se ha producido un error en esta expresion\n");
	esintacticos++;
}

bool perteneceTablaS(char *c) {
	if ((finalLS(tablaSimb)!=buscaLS(tablaSimb, c))) return true;
	return false;
}

void anadeEntrada(char *c, Tipo t) {
	Simbolo s;
	s.tipo = t;
	s.nombre = strdup(c);
	s.valor=contCadenas;
	insertaLS(tablaSimb, finalLS(tablaSimb), s);
}

bool esConstante(char *c) {
	PosicionLista p = buscaLS(tablaSimb, c);
	if (p!=finalLS(tablaSimb)) {
		Simbolo s = recuperaLS(tablaSimb, p);
		if (s.tipo==CONSTANTE) return true;
	}
	return false;
}

char* obtenerReg() {
	int i=0;
	while ((i<10) && (registros[i]!=0)) {
		i++;
	}
	if (i==10) {
		printf("Todos los registros están ocupados");
		return NULL;
	}
	registros[i]=1;
	char aux[16];
	sprintf(aux, "$t%d",i);
	return strdup(aux);
}

void liberarReg(char *a) {
	registros[a[2]-'0']=0;
}

void imprimirCodigo(ListaC codigo) {
	PosicionListaC p = inicioLC(codigo);
	while (p != finalLC(codigo)) {
		Operacion oper = recuperaLC(codigo, p);

		if (oper.op[0] == '$') {
			printf("%s",oper.op);
		}
		else {
			printf("\t");
		printf("%s",oper.op);
		}
		if (oper.res) printf(" %s",oper.res);
		if (oper.arg1) printf(",%s",oper.arg1);
		if (oper.arg2) printf(",%s",oper.arg2);
		printf("\n");
		p = siguienteLC(codigo,p);
	}
	printf("##############\n");
	printf("# Fin\n");
	printf("\tjr $ra");
}

char *concatena_(char *identificador, char *a) {
	char s[16];
	strcat(strcpy(s, a), identificador);
	return strdup(s);
}

char *obtenerEtiqueta() {
	char aux[16];
	sprintf(aux, "$l%d", contadorEtiquetas++);
	return strdup(aux);
}

void imprimirTablaS() {
	if (elexicos!=0 || esintacticos!=0 || esemanticos!=0) {
		printf("--------------------\n");
		printf("Errores léxicos: %d\n", elexicos);
		printf("Errores sintácticos: %d\n", esintacticos);
		printf("Errores semánticos: %d\n", esemanticos);
	}
	else {
		printf("############################\n");
		printf("# Sección de datos\n");
		printf(".data\n");
		printf("\n");

		PosicionLista p = inicioLS(tablaSimb);
		char *ids[longitudLS(tablaSimb)];

		int j = 0;
		while (p != finalLS(tablaSimb)) {
			Simbolo s = recuperaLS(tablaSimb, p);
			if (s.tipo == CADENA) {
				printf("$str%d:\n\t.asciiz %s\n", s.valor+1, s.nombre);
			}
			else if (s.tipo == VARIABLE || s.tipo == CONSTANTE) {
				ids[j] = s.nombre;
				j++;
			}
			p = siguienteLS(tablaSimb, p);
		}
		for (int k = 0; k < j; k++) {
			printf("_%s:\n\t.word 0\n", ids[k]);
		}
		printf("\n");
		printf("###################\n");
		printf("# Seccion de codigo\n");
		printf("\t.text\n");
		printf("\t.globl main\n");
		printf("main:\n");
	}
}
