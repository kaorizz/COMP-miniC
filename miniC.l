%{
#include "miniC.tab.h"
#include <stdlib.h>
int elexicos=0;
%}
letra		[a-zA-Z]
digito		[0-9]
entero		{digito}+

%option yylineno


%x COMENT

%%
"/*"			{BEGIN(COMENT);}
<COMENT>[^*]*		;
<COMENT>[*]+[^*/]*	;
<COMENT><<EOF>>	{BEGIN 0;printf("Error: comentario no cerrado iniciado en linea %d\n", yylineno);elexicos++;}
<COMENT>[*]+[/]	{BEGIN 0;}


void			return VOID;
var			return VAR;
const			return CONST;
if			return IF;
else			return ELSE;
while			return WHILE;
print			return PRINT;
read			return READ;
({letra}|_)({letra}|{digito}|_){0,15}	{yylval.lexema=strdup(yytext);return ID;}
({letra}|_)({letra}|{digito}|_){16,}	{printf("Error: identificador demasiado largo en la linea %d\n", yylineno);yylval.lexema=strdup(yytext);elexicos++;return ID;}
";"			return SEMICOLON;
","			return COMMA;
"+"			return PLUSOP;
"-"			return MINUSOP;
"*"			return ASTERISKOP;
"/"			return SLASHOP;
"="			return EQUALOP;
"("			return LPAREN;
")"			return RPAREN;
"{"			return LKEY;
"}"			return RKEY;
\"[^"\n]*\"		{yylval.lexema=strdup(yytext);return STRING;}
\"[^"\n]*		{printf("Error: cadena sin cerrar en la linea %d\n", yylineno);elexicos++;}
\/\/[^\n]*		;
[ \n\t]+		;
[^a-zA-Z0-9\n\t;,+\-*/_=(){}"]+	{printf("Error léxico en la cadena %s en la línea %d\n", yytext, yylineno);elexicos++;}
{entero}		{if(atoll(yytext)>2147483648) printf("Error: número fuera de rango");yylval.lexema=strdup(yytext);return NUM;elexicos++;}
%%

