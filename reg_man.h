#ifndef REG_MAN_H
#define REG_MAN_H

#include <iostream>
#include <string>
#include "basic.h"

using namespace std;

#define NUMREG 4

#define NEXT(cur) (cur+1)%NUMREG
#define PREV(cur) (cur+NUMREG-1)%NUMREG

class RegMan {
public:
	string allocate(basicType t) {
		cout<<"Allocate"<<endl;

		if(!status[cur]) {
			moveToStack(cur);
			fcount[cur]++;
		} else {
			status[cur] = false;
		}
		string reg = numtoreg(cur);
		cur = NEXT(cur);
		types.push_back(t);

		return reg;
	}

	void free() {
		cout<<"Free"<<endl;

		cur = PREV(cur);
		status[cur] = true;
		types.pop_back();
		cout<<"FreeEnd"<<endl;
	}

	void prepare(string reg) {
		int right = regtonum(reg);
		int left = NEXT(right);

		if(fcount[left] == fcount[right]) {
			return;
		} else if(fcount[right] == fcount[left]+1) {
			getFromStack(right);
			fcount[right]--;
		} else if(fcount[right]+1 != fcount[left]) {
			cerr<<"Error: Register Manager "<<reg<<" "<<fcount[left]<<" "<<fcount[right]<<endl;
		}
	}

	RegMan() {
		cout<<"yo"<<endl;
		cur = 0;
		for (int i = 0; i < NUMREG; ++i)
		{
			status[i] = true;
			fcount[i] = 0;
		}
		cout<<"yo"<<endl;
	}
private:
	int cur;
	bool status[NUMREG];
	int fcount[NUMREG];

	vector<basicType> types;

	string numtoreg(int n) {
		return string("e")+char('a'+n)+"x";
	}

	int regtonum(string reg) {
		return reg[1]-'a';
	}

	void moveToStack(int r) {
		string reg = numtoreg(r);
		code<<"l"<<++label<<": "
			<<"push"<<(types[types.size()-4]==cfloat?"f":"i")
			<<"("<<reg<<");"<<endl;
	}

	void getFromStack(int r) {
		string reg = numtoreg(r);
		code<<"l"<<++label<<": "
			<<"load"<<(types[types.size()-1]==cfloat?"f":"i")
			<<"(ind(esp),"<<reg<<");"<<endl;
		code<<"pop"<<(types[types.size()-1]==cfloat?"f":"i")
			<<"(1);"<<endl;
	}
};

#undef NEXT
#undef PREV

#endif // REG_MAN_H
