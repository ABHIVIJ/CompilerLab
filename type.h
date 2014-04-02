typedef struct arg_list_type
{
	int type ;	//1 for int type
			//2 for bool type
	char *name ;
	int ref ;	//1 if call by reference
			//0 else
	struct arg_list_type *next_arg ;
}arg_list_type ;

typedef struct gsymbol
{
	char *name ;
	int type ;	//1 for int type
			//2 for bool type
			//for functions this indicates the return type
	int size ;
	union
	{	
		int binding ;	//location in memory for variables 
		int label ;	//labelcnt for functions
	}

	int func_flag ; //0 for variable
			//1 for function
	arg_list_type *arguments ;
	struct gsymbol *next ;
}gsym ;

typedef struct lsymbol
{
	char *name ;				
	int type ;
	int binding ;				//in stage 9 binding is not given any value
	struct lsymbol *next ;
}lsym ;

typedef struct node_des
{
	int node_type ; //0 for num
		        //1 for operator
			//2 for id	//22 for array		//-2 for &id
			//3 for statements
			//4 for slist-no value assigned for val or spec
			//5 for function call

	int type;	//0 for no type
			//1 for int type
			//2 for bool type

	union
	{
		int val ;	//for num
		char *name ;	//for id
		int spec ; 	//for operator and statements : the corresponding tokens (as a character or the value assigned by lex to the 					//								token will be passed) 
				//	x - return
	};
	struct node_des *st1, *st2, *st3 ; //for actual parameters st3 points to next argument

	gsym *gentry ;	//NULL for elements except id

	lsym *lentry ; //NULL for all elements except local id

}node ;	

//for function call st1 contains the arguments

