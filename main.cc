#include <iostream>
#include <stdio.h>
#include <string>
#include "Scanner.h"
#include "Parser.h"

using namespace std;

extern global_sym g_sym;
extern map<std::string,abstract_astnode *> ast;
extern ofstream code;

int main ()
{
	Parser parser;
	parser.line_no=1;
	parser.parse();

	// cout<<"yoyo"<<endl;
	g_sym.dump_all();

	// string s;
	for (map<std::string,abstract_astnode *>::iterator i = ast.begin(); i != ast.end(); ++i)
	{
		g_sym.set_l_sym(i->first);
		// cout<<"yoyo"<<endl;
		code<<"void "<<i->first<<"() {"<<endl;
		i->second->generate_code();
		code<<"}"<<endl<<endl;
	}
}
