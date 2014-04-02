%{
	#include<stdlib.h>
	#include<string.h>
	#include "type.h"
	#include "y.tab.h"
	void yyerror(char *) ;
%}

%%
[0-9]+				{
					yylval.val = atoi(yytext) ;
					return NUM ;
				}

[-+*/();,=><%&\[\]\(\)\{\}]	return *yytext ;

"decl" 				return DECL ;

"enddecl"			return ENDDECL ;

"integer" 			return INTEGER ;

"boolean"			return BOOLEAN ;

"TRUE"				return TRUE ;

"FALSE"				return FALSE ;

"AND"				return AND ;

"OR"				return OR ;

"NOT"				return NOT ;

"=="				return EQ ;

"!="				return NE ;

"<="				return LE ;

">="				return GE ;

"read"				return READ ;

"write"				return WRITE ;

"if"				return IF ;

"then" 				return THEN ;

"else" 				return ELSE ;

"endif" 			return ENDIF ;

"while" 			return WHILE ;

"do"				return DO ;

"endwhile"			return ENDWHILE ;	

"begin"				return BGN ;

"end"				return END ;

"main"				return MAIN ;

"return"			return RETURN ;

[a-zA-Z_]+[a-zA-Z_0-9]*		{
					yylval.name = strdup(yytext) ;
					return ID ;
				}

[ \t\n]				;

.				yyerror("invalid character") ;

%%

int yywrap(void)
{
	return 1 ;
}
