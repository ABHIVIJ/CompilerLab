%{
	#include<stdio.h>
	#include<string.h>
	#include<stdlib.h>
	#include "type.h"

	node *create_node(int n_type, char sp, int num, char *name, node *e1, node *e2, node *e3) ;

	void ginstall(char *name,int type,int size) ;
	gsym *glookup(char *name) ;
	
	void codegen_main(node *e) ;
	int codegen(node *e) ;
	void next_reg() ;
	void free_reg() ;

	int yylex(void) ;
	void yyerror(char *) ;

	int t_num ;		//1 for int
				//2 for bool

	int mem_index = 0 ;

	gsym *gtable = NULL ;

	int reg_cnt, label_cnt ;

	FILE *fp ;

	FILE *yyin;
	
%}

%union
{
	int val ;
	char *name ;
	node *nptr ;
};

%token <val> NUM
%token <name> ID
%token UMINUS READ WRITE IF THEN ELSE ENDIF WHILE DO ENDWHILE DECL ENDDECL INTEGER BOOLEAN TRUE FALSE BGN END

%nonassoc '>' '<' EQ GE LE NE 
%left AND OR
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS NOT 

%type <nptr> expr stmt slist

%%

pgm:
	declaration BGN slist END				{
									printf("AST created\n\n") ;
			
									codegen_main($3) ;
									printf("Code generation complete\n") ;

									exit(0) ;
								}
	;

declaration:
	DECL dec_list ENDDECL					
	;

dec_list:
	dec_stat dec_list					
	|							
	;

dec_stat:
	type var_list ';'					

type:
	INTEGER 						{t_num = 1 ;}
	| BOOLEAN						{t_num = 2 ;}

var_list:
	ID							{ginstall($1,t_num,1);}
	| ID '[' NUM ']' 					{ginstall($1,t_num,$3);}
	| var_list ',' ID					{ginstall($3,t_num,1);}
	| var_list ',' ID '[' NUM ']'  			{ginstall($3,t_num,$5);}	
	;

slist:
	slist stmt						{$$ = create_node(4,'a',0,"none",$1,$2,NULL);}
	| stmt							{$$ = $1;}
	;

stmt:
	ID '=' expr ';'					{
									node *temp = create_node(2,'a',0,$1,NULL,NULL,NULL) ;
									$$ = create_node(3,'=',0,"none",temp,$3,NULL);
								}

	| ID '[' expr ']' '=' expr ';'				{
									node *temp = create_node(22,'a',0,$1,$3,NULL,NULL) ;
									$$ = create_node(3,'=',0,"none",temp,$6,NULL) ;
								}

	| READ '(' ID ')' ';'					{
									node *temp = create_node(2,'a',0,$3,NULL,NULL,NULL) ;
									$$ = create_node(3,'r',0,"none",temp,NULL,NULL);
								}

	| READ '(' ID '[' expr ']' ')' ';'			{	
									node *temp = create_node(22,'a',0,$3,$5,NULL,NULL) ;
									$$ = create_node(3,'r',0,"none",temp,NULL,NULL);
								}

	| WRITE '(' expr ')' ';'				{$$ = create_node(3,'p',0,"none",$3,NULL,NULL);}
	| IF '(' expr ')' THEN slist ENDIF ';'			{$$ = create_node(3,'i',0,"none",$3,$6,NULL);} 
	| IF '(' expr ')' THEN slist  ELSE slist ENDIF ';'	{$$ = create_node(3,'e',0,"none",$3,$6,$8);}
	| WHILE '(' expr ')' DO slist ENDWHILE ';'		{$$ = create_node(3,'w',0,"none",$3,$6,NULL);}
	;

expr:
	ID							{$$ = create_node(2,'a',0,$1,NULL,NULL,NULL);}
	| ID '[' expr ']'					{$$ = create_node(22,'a',0,$1,$3,NULL,NULL);}
	| NUM							{$$ = create_node(0,'a',$1,"none",NULL,NULL,NULL);}
	| '-' NUM %prec UMINUS 					{$$ = create_node(0,'a',-$2,"none",NULL,NULL,NULL);}
	| TRUE							{$$ = create_node(0,'b',1,"none",NULL,NULL,NULL);}
	| FALSE							{$$ = create_node(0,'b',0,"none",NULL,NULL,NULL);}
	| expr '+' expr						{$$ = create_node(1,'+',0,"none",$1,$3,NULL);}
	| expr '-' expr						{$$ = create_node(1,'-',0,"none",$1,$3,NULL);}
	| expr '*' expr						{$$ = create_node(1,'*',0,"none",$1,$3,NULL);}
	| expr '/' expr						{$$ = create_node(1,'/',0,"none",$1,$3,NULL);}
	| expr '%' expr						{$$ = create_node(1,'%',0,"none",$1,$3,NULL);}
	| '(' expr ')'						{$$ = $2;}
	| expr '>' expr 					{$$ = create_node(1,'>',0,"none",$1,$3,NULL);}
	| expr '<' expr						{$$ = create_node(1,'<',0,"none",$1,$3,NULL);}
	| expr LE expr						{$$ = create_node(1,'L',0,"none",$1,$3,NULL);}
	| expr GE expr						{$$ = create_node(1,'G',0,"none",$1,$3,NULL);}
 	| expr EQ expr						{$$ = create_node(1,'E',0,"none",$1,$3,NULL);}
 	| expr NE expr						{$$ = create_node(1,'N',0,"none",$1,$3,NULL);}
	| expr AND expr						{$$ = create_node(1,'A',0,"none",$1,$3,NULL);}
	| expr OR expr						{$$ = create_node(1,'O',0,"none",$1,$3,NULL);}
	| NOT expr 						{$$ = create_node(1,'!',0,"none",$2,NULL,NULL);}
	;

%%
void ginstall(char *name,int type,int size) 
{
	gsym *g, *prev ;
	prev = glookup(name) ;
	if(prev != NULL)
	{
		prev->type = type ;
		prev->size = size ;
		printf("Variable redeclared\n") ;
	}
	else
	{	
		g = (gsym *)malloc(sizeof(gsym)) ;
		if(g == NULL)
			yyerror("No memory space !") ;
		g->name = strdup(name) ;
		g->type = type ;
		g->size = size ;

		g->binding = mem_index ;

		mem_index += size ;

		g->next = gtable ;				//inserts a new variable entry at the beginning of the symbol table
		gtable = g ;
	}
	return ;
}

gsym *glookup(char *name)
{
	gsym *g ;
	g = gtable ;
	while((g != NULL)&&(strcmp(g->name,name) != 0))
		g = g->next ; 
	return g ;
}

node *create_node(int n_type, char sp, int num, char *name, node *e1, node *e2, node *e3) 
{
	node *p ;
	gsym *g ;
	p = (node *)malloc(sizeof(node)) ;
	if(p == NULL)
		yyerror("No memory space !") ;
	p->node_type = n_type ;
	switch(n_type)
	{
		case 0 		:		p->val = num ;
						if(sp == 'b')
							p->type = 2 ;
						else
							p->type = 1 ;
						p->gentry = NULL ;
						break ;

		case 1 		:		p->spec = sp ;
						switch(sp)
						{
							case '+' :
							
							case '-' :

							case '*' :	

							case '/' :	

							case '%' :	if((e1->type == 1)&&(e2->type == 1))
										p->type = 1 ;
									else
										yyerror("Type mismatch\n") ;
									break ;

					   		case '>' :
			
							case '<' :

							case 'L' :
		
							case 'G' :

							case 'E' :	

							case 'N' :	if((e1->type == 1)&&(e2->type == 1))
										p->type = 2 ;
									else
										yyerror("Type mismatch NOT EQUAL\n") ;
									break ;

							case 'A' :	

							case 'O' :	if((e1->type == 2)&&(e2->type == 2))
										p->type = 2 ;
									else
										yyerror("Type mismatch\n") ;
									break ;

							case '!' :	if(e1->type == 2)
										p->type = 2 ;
									else
										yyerror("Type mismatch NOT\n") ;
									break ;

						}		
						p->gentry = NULL ;		
						break ;

		case 2		: 		

		case 22		:		g = glookup(name) ;
						if(g == NULL)
							yyerror("Variable not declared\n") ;
						p->gentry = g ;
						p->name = strdup(name) ;
						p->type = g->type ;
						break ;

		case 3		:		p->spec = sp ;
						switch(sp)
						{
							case 'r' :	if(e1->type == 2)
										yyerror("Type mismatch\n") ;
									p->type = 0 ;
									break ;

							case 'p' :	if(e1->type == 2)
										yyerror("Type mismatch\n") ;
									p->type = 0 ;
									break ;

							case 'i' :

							case 'e' :
	
							case 'w' :	if(e1->type == 2)
										p->type = 0 ;
									else
										yyerror("Type mismatch\n") ;
									break ;
							
							case '=' :	if((e1->type==1 && e2->type==1)||(e1->type==2 && e2->type==2))
										p->type = 0 ;
									else
										yyerror("Type mismatch\n") ;
									break ;
						}
						p->gentry = NULL ;
						break ;

		case 4		: 		p->type = 0 ;
						p->gentry = NULL ;
						break ;
	}
	
	p->st1 = e1 ;
	p->st2 = e2 ;
	p->st3 = e3 ;

	return p ;
}

void codegen_main(node *e)
{
	int num ;
	fp = fopen("m_code","w") ;
	fprintf(fp,"START\n") ;
	num = codegen(e) ;
	fprintf(fp,"HALT\n") ;
	fclose(fp) ;
	return ;
}

int codegen(node *e)
{
	int a, b ;
	int l_cnt1, l_cnt2 ;
	
	switch(e->node_type)
	{
		case 0		:	fprintf(fp,"MOV R%d, %d\n",reg_cnt,e->val) ;	
					next_reg() ;
					return reg_cnt-1 ;	


		case 1		:	a = codegen(e->st1) ;
					if(e->spec != '!')
						b = codegen(e->st2) ;
					switch(e->spec)
					{
						case '+'	:	fprintf(fp,"ADD R%d, R%d\n",a,b) ;
									break ;

						case '-'	:	fprintf(fp,"SUB R%d, R%d\n",a,b) ;
									break ;
							
						case '*'	:	fprintf(fp,"MUL R%d, R%d\n",a,b) ;
									break ;

						case '/'	:	fprintf(fp,"DIV R%d, R%d\n",a,b) ;
									break ;

						case '%'	:	fprintf(fp,"MOD R%d, R%d\n",a,b) ;
									break ;

						case '<'	:	fprintf(fp,"LT R%d, R%d\n",a,b) ;
									break ;
		
						case '>'	:	fprintf(fp,"GT R%d, R%d\n",a,b) ;
									break ;

						case 'L'	: 	fprintf(fp,"'L' R%d, R%d\n",a,b) ;
									break ;

						case 'G'	: 	fprintf(fp,"'G' R%d, R%d\n",a,b) ;
									break ;

						case 'E'	: 	fprintf(fp,"'E' R%d, R%d\n",a,b) ;
									break ;

						case 'N'	: 	fprintf(fp,"'N' R%d, R%d\n",a,b) ;
									break ;

						case 'A' 	:	fprintf(fp,"JZ R%d, L%d\n",a,label_cnt++) ;
									fprintf(fp,"MOV R%d, R%d\n",a,b) ;
									fprintf(fp,"JMP L%d\n",label_cnt++) ;
									fprintf(fp,"L%d :\n",label_cnt-2) ;
									fprintf(fp,"MOV R%d, %d\n",a,0) ;
									fprintf(fp,"L%d :\n",label_cnt-1) ;
									break ;

						case 'O'	:	fprintf(fp,"JZ R%d, L%d\n",a,label_cnt++) ;
									fprintf(fp,"MOV R%d, %d\n",a,1) ;
									fprintf(fp,"JMP L%d\n",label_cnt++) ;
									fprintf(fp,"L%d :\n",label_cnt-2) ;
									fprintf(fp,"MOV R%d, R%d\n",a,b) ;
									fprintf(fp,"L%d :\n",label_cnt-1) ;
									break ;

						case '!'	:	fprintf(fp,"MOV R%d, %d\n",reg_cnt,1) ;
									fprintf(fp,"SUB R%d, R%d\n",reg_cnt,a) ;
									fprintf(fp,"MOV R%d, %d\n",a,reg_cnt) ;
									break ;

					}	
					if(e->spec != '!')	
						free_reg() ;
					return a ;
					
		case 2		:	fprintf(fp,"MOV R%d, [%d]\n",reg_cnt,e->gentry->binding) ;
					next_reg() ;
					return reg_cnt-1 ;

		case 22		:	a = codegen(e->st1) ;
					fprintf(fp,"MOV R%d, %d\n",reg_cnt,e->gentry->binding) ;
					fprintf(fp,"ADD R%d, R%d\n",a,reg_cnt) ;
					fprintf(fp,"MOV R%d, [R%d]\n",a,a) ;//here we used R0 but curr reg is R1:so no need of next or free
					return reg_cnt-1 ;
					
		case 3		:	switch(e->spec)
					{
						case '='	:	a = codegen(e->st2) ;
									if(e->st1->node_type == 2)
										fprintf(fp,"MOV [%d], R%d\n",e->st1->gentry->binding,a) ;
									else
									{
										b = codegen(e->st1->st1) ;
										fprintf(fp,"MOV R%d, %d\n",reg_cnt,
													       e->st1->gentry->binding) ;
										fprintf(fp,"ADD R%d, R%d\n",b,reg_cnt) ;
										fprintf(fp,"MOV [R%d], R%d\n",b,a) ;
										free_reg() ;
									}
									free_reg() ;
									break ;
									
						case 'r'	:	if(e->st1->node_type == 2)
									{
										fprintf(fp,"IN R%d\n",reg_cnt) ;
									     	fprintf(fp,"MOV [%d], R%d\n",e->st1->gentry->binding,
																reg_cnt) ;
									}
									else
									{
										a = codegen(e->st1->st1) ;
                     								fprintf(fp,"MOV R%d, %d\n",reg_cnt,
														e->st1->gentry->binding) ;
										fprintf(fp,"ADD R%d, R%d\n",a,reg_cnt) ;
										fprintf(fp,"IN R%d\n",reg_cnt) ;
										fprintf(fp,"MOV [R%d], R%d\n",a,reg_cnt) ; 
										free_reg() ; //reg a can be reused
									}
									break ;

						case 'p'	:	a = codegen(e->st1) ;
									fprintf(fp,"OUT R%d\n",a) ;
									free_reg() ;
									break ;

						case 'i'	:	a = codegen(e->st1) ;
									l_cnt1 = label_cnt ;
									fprintf(fp,"JZ R%d, L%d\n",a,l_cnt1) ;
									free_reg() ;
									b = codegen(e->st2) ;
									fprintf(fp,"L%d :\n",l_cnt1) ;
									label_cnt++ ;
									break ;

						case 'e'	:	a = codegen(e->st1) ;				//condition
									l_cnt1 = label_cnt++ ;
									l_cnt2 = label_cnt++ ;
									fprintf(fp,"JZ R%d, L%d\n",a,l_cnt1) ;		//JZ Ri,L0
									free_reg() ;
									b = codegen(e->st2) ;				//if part
									fprintf(fp,"JMP L%d\n",l_cnt2) ;		//JMP L1
									fprintf(fp,"L%d :\n",l_cnt1) ;			//L0:
									b = codegen(e->st3) ;				//else part
									fprintf(fp,"L%d :\n",l_cnt2) ;			//L1:
									break ;

						case 'w'	:	l_cnt1 = label_cnt++ ;
									l_cnt2 = label_cnt++ ;

									fprintf(fp,"L%d :\n",l_cnt2) ;			//L1:
					
									a = codegen(e->st1) ;				//condition
									fprintf(fp,"JZ R%d, L%d\n",a,l_cnt1) ;		//JZ Ri,L0
									free_reg() ;

									b = codegen(e->st2) ;				//statements	
									fprintf(fp,"JMP L%d\n",l_cnt2) ;		//JMP L1

									fprintf(fp,"L%d :\n",l_cnt1) ;			//L0:

									break ;
					}
					return -1 ;

		case 4		:	a = codegen(e->st1) ;
					b = codegen(e->st2) ;
					return -1 ;
	}
}

void next_reg()
{
	if(reg_cnt == 7)
		yyerror("Not enough registers\n") ;
	else
		reg_cnt ++ ;
}

void free_reg()
{
	reg_cnt -- ;
}


void yyerror(char *s)	
{
	fprintf(stderr, "%s\n",s) ;
	exit(1) ;
}

int main(int argc,char *argv[])	
{

	yyin = fopen(argv[1],"r");
	yyparse() ;
	fclose(yyin) ;
	return 0 ;
}
