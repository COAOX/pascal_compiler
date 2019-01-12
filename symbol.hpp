#ifndef INCLUDE_H

#define INCLUDE_H

#include <string>
#include <iostream>

using namespace std;

class Array
{
	public:
		int start;
		int end;
		int type;
};

class Symbol
{
  public:
	bool isReference;
	bool isGlobal;
	int type;
	int token;
	int address;
	string name;
	Array array;
	vector<int> parameterList;
};

class SymbolTable
{
	int tempsCount = 0;
	int labelsCount = 1;
	int globalAddressTop = 0;
	int localAddressTop = 0;
	vector<Symbol> symbolTable;

  public:
	Symbol &operator[](int index)
	{
		return symbolTable[index];
	}
	SymbolTable();
	int insert(string name, int token, int type);
	int insertTempSymbol(int type);
	int pickType(int index1, int index2);
	int insertConst(string val, int type);
	int insertLabel();
	int lookup(string name);
	int lookupLocal(string name);
	int lookupLocalOrInsert(string s, int token, int type);
	int lookupFunction(string s);
	int allocateNewVariable(Symbol& symbol);
	int getSymbolSize(Symbol& symbol);
	void clearLocalSymbols();
	void dump();
};

#endif