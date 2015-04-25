%%
[ \t]+                                    					// skip white space chars.
\n															Parser::line_no++;
void														return Parser::VOID;
int															return Parser::INT;
float														return Parser::FLOAT;
return														return Parser::RETURN;
if															return Parser::IF;
else														return Parser::ELSE;
while														return Parser::WHILE;
for															return Parser::FOR;
\|\|														return Parser::OR_OP;
&&															return Parser::AND_OP;
==															return Parser::EQ_OP;
!=															return Parser::NE_OP;
\<=															return Parser::LE_OP;
\>=															return Parser::GE_OP;
\+\+														return Parser::INC_OP;
([1-9][0-9]*)|(0[bB][01]+)									{Parser::d_val__=std::string(matched());return Parser::INT_CONST;}
(0[xX][0-9a-fA-F]+)|(0[0-7]*)								{Parser::d_val__=std::string(matched());return Parser::INT_CONST;}
(([0-9]+\.[0-9]*)|([0-9]*\.[0-9]+)([eE][+-]?[0-9]+)?)		{Parser::d_val__=std::string(matched());return Parser::FLOAT_CONST;}
\"([^\\"]|(\\(a|[^a])))*\"									{Parser::d_val__=std::string(matched());return Parser::STRING_LITERAL;}
[[:alpha:]_][[:alpha:][:digit:]_]*							{Parser::d_val__=std::string(matched());return Parser::IDENTIFIER;}
.															return matched()[0];
