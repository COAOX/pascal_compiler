#ifndef INCLUDE_H

#define INCLUDE_H

#include <string>
#include <iostream>

using namespace std;

class Symbol {
public:
	bool isReference;
	bool isGlobal;
	int type;                                   
	int address;
	string name;                                
};

#endif