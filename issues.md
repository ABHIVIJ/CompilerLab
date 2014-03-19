issue1

mcgen.y: warning: 3 nonterminals useless in grammar
mcgen.y: warning: 6 rules useless in grammar
mcgen.y:82.9-17: warning: nonterminal useless in grammar: gdec_stat
mcgen.y:87.14-21: warning: nonterminal useless in grammar: gid_list
mcgen.y:96.22-24: warning: nonterminal useless in grammar: gid
mcgen.y:82.9-27: warning: rule useless in grammar: gdec_list: gdec_stat gdec_list
mcgen.y:87.9-25: warning: rule useless in grammar: gdec_stat: type gid_list ';'
mcgen.y:96.9-24: warning: rule useless in grammar: gid_list: gid_list ',' gid
mcgen.y:100.9-92: warning: rule useless in grammar: gid: ID
mcgen.y:101.11-93: warning: rule useless in grammar: gid: ID '[' NUM ']'
mcgen.y:102.11-92: warning: rule useless in grammar: gid: ID '(' arg_list ')'

-----------------------------------------------------------------------------------------------------------------------------------------
Resolved -
	Cause :  Rule 	gid_list: gid_list ',' gid 	has no base case

*****************************************************************************************************************************************

issue2

add_to_ltable(arg_list_type *arguments)    
	-does not store ref value in ltable
	-not sure if this is required

-----------------------------------------------------------------------------------------------------------------------------------------
Resolved - 
	Cause : ref value is stored properly. no case was given for -2 in create_node function

*****************************************************************************************************************************************

issue3

In func call args are in correct order, but in defn and decl they are in reverse.

-----------------------------------------------------------------------------------------------------------------------------------------
Resolved -
	By : passing arguments in correct order to link_arg

*****************************************************************************************************************************************
