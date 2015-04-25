%scanner Scanner.h
%scanner-token-function d_scanner.lex()
%start translation_unit

%token INT_CONST FLOAT_CONST STRING_LITERAL IDENTIFIER
%token OR_OP AND_OP EQ_OP NE_OP LE_OP GE_OP INC_OP
%token VOID INT FLOAT RETURN IF ELSE WHILE FOR

%polymorphic stmt: stmt_ast*; expr: exp_ast*; arr: arr_ast*; op: int; func: func_ast*; block: block_ast*; str: std::string; btype: basicType; ls: std::list<std::string>*;
%type <block> statement_list
%type <stmt> statement assignment_statement iteration_statement selection_statement compound_statement
%type <expr> primary_expression postfix_expression logical_and_expression expression equality_expression
%type <expr> unary_expression multiplicative_expression additive_expression relational_expression
%type <op> unary_operator
%type <arr> l_expression
%type <func> expression_list
%type <str> INT_CONST FLOAT_CONST STRING_LITERAL IDENTIFIER fun_declarator declarator constant_expression
%type <btype> type_specifier
%type <ls> declarator_list

%%

translation_unit
	: function_definition
	| translation_unit function_definition
	;

function_definition
	: type_specifier fun_declarator
	{
		g_entry *entry = new g_entry($1,l_sym);
		std::pair<bool,std::string> err=g_sym.insert($2,entry);
		if(!err.first)
		{
			std::cerr<<"Error : Function name "<<err.second<<" in line number "<<Parser::line_no<<" already exists."<<std::endl;
			exit(0);
		}
		cur_return=$1;
	}
	compound_statement
	{
		ast[$2] = $4;
	}
	;

type_specifier
	: VOID
	{
		$$=cvoid;
	}
	| INT
	{
		$$=cint;
	}
	| FLOAT
	{
		$$=cfloat;
	}
	;

fun_declarator
	: IDENTIFIER '('
	{
		l_sym = new local_sym();
		$$ = $1;
		offset = 4;
	}
	parameter_list ')'
	| IDENTIFIER '(' ')'
	{
		l_sym = new local_sym();
		$$ = $1;
		offset = 4;
	}
	;

parameter_list
	: parameter_declaration
	| parameter_list ',' parameter_declaration
	;

parameter_declaration
	: type_specifier declarator
	{
		l_entry *entry = new l_entry($1,$2);
		std::pair<bool,std::string> err = l_sym->params_insert(entry);
		if(!err.first)
		{
			std::cerr<<"Error : Parameter name "<<err.second<<" in line number "<<Parser::line_no<<" already exists."<<std::endl;
			exit(0);
		}
	}
	;

declaration_list
	: declaration
	| declaration_list declaration
	;

declaration
	: type_specifier declarator_list ';'
	{
		if($1==cvoid)
		{
			std::cerr<<"Error : Variables in line number "<<Parser::line_no<<" declared void."<<std::endl;
			exit(0);
		}
		std::pair<bool,std::string> err = l_sym->local_insert($1,$2);
		if(!err.first)
		{
			std::cerr<<"Error : Variable name "<<err.second<<" in line number "<<Parser::line_no<<" already exists."<<std::endl;
			exit(0);
		}
	}
	;

declarator_list
	: declarator
	{
		$$ = new list<string>();
		($$)->push_back($1);
	}
	| declarator_list ',' declarator
	{
		$$ = $1;
		($$)->push_back($3);
	}
	;

declarator
	: IDENTIFIER
	{
		$$ = $1;
	}
	| declarator '[' constant_expression ']'
	{
		$$ = std::string("[") + $3 + "]" + $1;
	}
	;

constant_expression
	: INT_CONST
	{
		$$ = $1;
	}
	| FLOAT_CONST
	{
		std::cerr<<"Error : Array declared with non-integer size "<<$1<<" in line number "<<Parser::line_no<<std::endl;
		exit(0);
	}
	;

compound_statement
	: '{' '}'
	| '{' statement_list '}'
	{
		$$ = $2;
	}
    | '{'
    {
    	offset = 0;
    }
    declaration_list statement_list '}'
    {
		$$ = $4;
	}
	;

statement_list
	: statement
	{
		block_ast *b=new block_ast();
		b->add_stmt($1);
		$$=b;
	}
	| statement_list statement
	{
		block_ast *b=new block_ast($1);
		b->add_stmt($2);
		$$=b;
	}
	;

statement
	: '{' statement_list '}'
	{
		$$=$2;
	}
	| selection_statement
	{
		$$=$1;
	}
	| iteration_statement
	{
		$$=$1;
	}
	| assignment_statement
	{
		$$=$1;
	}
	| RETURN expression ';'
	{
		if(($2)->getType().t!=NULL)
		{
			std::cerr<<"Error : Retrning an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e = $2;

		if(cur_return == cint && ($2)->getType().type == cfloat)
		{
			e = new cast_int_ast($2);
		}

		else if(cur_return == cfloat && ($2)->getType().type == cint)
		{
			e = new cast_float_ast($2);
		}

		if(cur_return!=e->getType().type)
		{
			std::cerr<<"Error : Return type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new return_ast(e);
	}
	| IDENTIFIER '('
	{
		if($1!="printf"&&!g_sym.present($1).first)
		{
			std::cerr<<"Error : Undefined reference to "<<$1<<" in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
	}
	expression_list ')' ';'
	{
		funcStmt_ast *temp=new funcStmt_ast($4,$1);
		if($1=="printf")
		{
			$$=temp;
		}
		else
		{
			vector<typeExp> call = temp->get_param_type();
			vector<typeExp> def = g_sym.get_param_type($1);
			if(call.size() != def.size()) {
				std::cerr<<"Error : Incorrect number of arguments to function "<<$1<<" in line number "<<Parser::line_no<<std::endl;
				exit(0);
			}

			for (int i = 0; i < call.size(); ++i)
			{
				if(call[i].type == cint && def[i].type == cfloat)
				{
					temp->cast(cfloat, i);
				}

				else if(call[i].type == cfloat && def[i].type == cint)
				{
					temp->cast(cint, i);
				}

				else if(!(call[i]==def[i]))
				{
					std::cerr<<"Error : Argument type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
					exit(0);
				}
			}

			$$=temp;
		}
	}
	;

assignment_statement
	: ';'
	{
		$$=new empty_ast();
	}
	|  l_expression '=' expression ';'
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Assigning to an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Assigning an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e = new cast_int_ast($3);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e = new cast_float_ast($3);
		}

		else if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new ass_ast($1,e);
	}
	;

expression
	: logical_and_expression
	{
		$$=$1;
	}
	| expression OR_OP logical_and_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($1->getType().type!=cint&&$1->getType().type!=cfloat)
		{
			std::cerr<<"Error : Invalid type on lhs of relational expression in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().type!=cint&&$3->getType().type!=cfloat)
		{
			std::cerr<<"Error : Invalid type on rhs of relational expression in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast($1,$3,1001);
	}
	;

logical_and_expression
	: equality_expression
	{
		$$=$1;
	}
	| logical_and_expression AND_OP equality_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($1->getType().type!=cint&&$1->getType().type!=cfloat)
		{
			std::cerr<<"Error : Invalid type on lhs of relational expression in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().type!=cint&&$3->getType().type!=cfloat)
		{
			std::cerr<<"Error : Invalid type on rhs of relational expression in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast($1,$3,1002);
	}
	;

equality_expression
	: relational_expression
	{
		$$=$1;
	}
	| equality_expression EQ_OP relational_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($1->getType().type!=cint&&$1->getType().type!=cfloat)
		{
			std::cerr<<"Error : Invalid type on lhs of relational expression in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().type!=cint&&$3->getType().type!=cfloat)
		{
			std::cerr<<"Error : Invalid type on rhs of relational expression in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast($1,$3,1003);
	}
	| equality_expression NE_OP relational_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast($1,$3,1004);
	}
	;

relational_expression
	: additive_expression
	{
		$$=$1;
	}
	| relational_expression '<' additive_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		else if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		$$=new op_ast(e1,e2,'<');
	}
	| relational_expression '>' additive_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		$$=new op_ast(e1,e2,'>');
	}
	| relational_expression LE_OP additive_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast(e1,e2,1005);
	}
	| relational_expression GE_OP additive_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast(e1,e2,1006);
	}
	;

additive_expression
	: multiplicative_expression
	{
		$$=$1;
	}
	| additive_expression '+' multiplicative_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast(e1,e2,'+');
	}
	| additive_expression '-' multiplicative_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast(e1,e2,'-');
	}
	;

multiplicative_expression
	: unary_expression
	{
		$$=$1;
	}
	| multiplicative_expression '*' unary_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast(e1,e2,'*');
	}
	| multiplicative_expression '/' unary_expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e1 = new cast_float_ast($1);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new op_ast(e1,e2,'/');
	}
	;

unary_expression
	: postfix_expression
	{
		$$=$1;
	}
	| unary_operator postfix_expression
	{
		if($2->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if(!($2->getType()==$2->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new unop_ast($1,$2);
	}
	;

postfix_expression
	: primary_expression
	{
		$$=$1;
	}
	| IDENTIFIER '(' ')'
	{
		if($1=="printf")
		{
			$$=new func_ast($1,cvoid);
		}
		else
		{
			pair<bool,basicType> err=g_sym.present($1);
			if(!err.first)
			{
				std::cerr<<"Error : Undefined reference to "<<$1<<" in line number "<<Parser::line_no<<"."<<std::endl;
				exit(0);
			}
			func_ast *temp=new func_ast($1,err.second);
			if(temp->get_param_type()!=g_sym.get_param_type($1))
			{
				std::cerr<<"Error : Incorrect number of arguments to function "<<$1<<" in line number "<<Parser::line_no<<std::endl;
				exit(0);
			}
			$$=temp;
		}
	}
	| IDENTIFIER '('
	{
		if($1!="printf" && !g_sym.present($1).first)
		{
			std::cerr<<"Error : Undefined reference to "<<$1<<" in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
	} expression_list ')'
	{
		func_ast *temp=new func_ast($4,$1,g_sym.present($1).second);
		if($1=="printf")
		{
			$$=temp;
		}
		else
		{
			vector<typeExp> call = temp->get_param_type();
			vector<typeExp> def = g_sym.get_param_type($1);
			if(call.size() != def.size()) {
				std::cerr<<"Error : Incorrect number of arguments to function "<<$1<<" in line number "<<Parser::line_no<<std::endl;
				exit(0);
			}
			for (int i = 0; i < call.size(); ++i)
			{
				if(call[i].type == cint && def[i].type == cfloat)
				{
					temp->cast(cfloat, i);
				}

				else if(call[i].type == cfloat && def[i].type == cint)
				{
					temp->cast(cint, i);
				}

				else if(!(call[i]==def[i]))
				{
					std::cerr<<"Error : Argument "<<i+1<<" to function "<<$1<<" in line number "<<Parser::line_no<<" does not match."<<std::endl;
					exit(0);
				}
			}

			$$=temp;
		}
	}
	| l_expression INC_OP
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new unop_ast(1000,$1);
	}
	;

primary_expression
	: l_expression
	{
		$$=$1;
	}
	| l_expression '=' expression
	{
		if($1->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		if($3->getType().t!=NULL)
		{
			std::cerr<<"Error : Using operation on an array variable in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		exp_ast *e1 = $1, *e2 = $3;

		if(($1)->getType().type == cint && ($3)->getType().type == cfloat)
		{
			e2 = new cast_int_ast($3);
		}

		else if(($1)->getType().type == cfloat && ($3)->getType().type == cint)
		{
			e2 = new cast_float_ast($3);
		}

		if(!($1->getType()==$3->getType()))
		{
			std::cerr<<"Error : Type mismatch in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}

		$$=new op_ast(e1,e2,'=');
	}
	| INT_CONST
	{
		$$=new int_ast($1);
	}
	| FLOAT_CONST
	{
		$$=new float_ast($1);
	}
	| STRING_LITERAL
	{
		$$=new str_ast($1);
	}
	| '(' expression ')'
	{
		$$=$2;
	}
	;

l_expression
	: IDENTIFIER
	{
		pair<bool,typeExp> err=l_sym->present($1);
		if(!err.first)
		{
			std::cerr<<"Error : Variable "<<$1<<" undeclared in line number "<<Parser::line_no<<"."<<std::endl;
			exit(0);
		}
		$$=new iden_ast($1,err.second);
	}
	| l_expression '[' expression ']'
	{
		if($1->getType().t == NULL)
		{
			cerr<<"Error : Subscripted value in line number "<<Parser::line_no<<" is not an array."<<endl;
			exit(0);
		}
		if(!($3->getType().t==NULL && $3->getType().type==cint))
		{
			cerr<<"Error : Array subscript in line number "<<Parser::line_no<<" is not an integer."<<endl;
			exit(0);
		}
		$$=new arr_ast($1,$3);
	}
	;

expression_list
	: expression
	{
		$$=new func_ast($1);
	}
	| expression_list ',' expression
	{
		$$=new func_ast($1,$3);
	}
	;

unary_operator
	: '-'
	{
		$$='-';
	}
	| '!'
	{
		$$='!';
	}
	;

selection_statement
	: IF '(' expression ')' statement ELSE statement
	{
		$$=new if_ast($3,$5,$7);
	}
	;

iteration_statement
	: WHILE '(' expression ')' statement
	{
		$$=new while_ast($3,$5);
	}
	| FOR '(' expression ';' expression ';' expression ')' statement
	{
		$$=new for_ast($3,$5,$7,$9);
	}
	;
