#include "global.hpp"
#include "parser.hpp"

using namespace std;

int SymbolTable::insert(string name, int token, int type)
{
	Symbol symbol;
	symbol.name = name;
	symbol.token = token;
	symbol.type = type;
	symbol.isGlobal = inGlobalScope;
	symbol.isReference = false;
	symbol.address = 0;

	symbolTable.push_back(symbol);
	return (int)(symbolTable.size() - 1);
}

int SymbolTable::insertTempSymbol(int type)
{
	string name = "$t" + to_string(tempsCount++);
	int id = insert(name, VAR, type);
	allocateNewVariable(symbolTable[id]);
	return id;
}

int SymbolTable::pickType(int index1, int index2)
{
	return (symbolTable[index1].type == REAL || symbolTable[index2].type == REAL) ? REAL : INTEGER;
}

int SymbolTable::insertConst(string val, int type)
{
	int num = lookup(val);

	if (num == -1)
	{
		num = insert(val, NUM, type);
	}
	return num;
}

int SymbolTable::insertLabel()
{
	string name = "lab" + to_string(labelsCount++);
	int id = insert(name, LABEL, NONE);
	return id;
}

SymbolTable::SymbolTable()
{
	Symbol read;
	read.name = ("read");
	read.isGlobal = true;
	read.isReference = false;
	read.token = PROC;
	symbolTable.push_back(read);

	Symbol write;
	write.name = ("write");
	write.isGlobal = true;
	write.isReference = false;
	write.token = PROC;
	symbolTable.push_back(write);

	Symbol lab0;
	lab0.name = ("lab0");
	lab0.isGlobal = true;
	lab0.isReference = false;
	lab0.token = LABEL;
	symbolTable.push_back(lab0);

	generateJump(lab0);
}

int SymbolTable::lookup(string name)
{
	int index = (int)(symbolTable.size() - 1); //look in reverse in order to find locals first

	for (; index >= 0; index--)
	{
		if (symbolTable[index].name == name)
		{
			return index;
		}
	}
	return -1;
}

int SymbolTable::lookupLocal(string name)
{
	int index = (int)(symbolTable.size() - 1);

	if (inGlobalScope)
	{
		for (; index >= 0; index--)
		{
			if (symbolTable[index].name == name)
			{
				return index;
			}
		}
	}
	else
	{
		for (; index >= 0; index--)
		{
			if (!symbolTable[index].isGlobal && symbolTable[index].name == name)
			{
				return index;
			}
		}
	}
	return -1;
}

int SymbolTable::lookupLocalOrInsert(string s, int token, int type)
{
	int value = lookupLocal(s);

	if (value == -1)
	{
		value = insert(s, token, type);
	}
	return value;
}

int SymbolTable::allocateNewVariable(Symbol &symbol)
{
	if (inGlobalScope == true)
	{
		symbol.address = globalAddressTop;
		globalAddressTop += getSymbolSize(symbol);
	}
	else
	{
		localAddressTop -= getSymbolSize(symbol);
		symbol.address = localAddressTop;
	}
}

int SymbolTable::getSymbolSize(Symbol &symbol)
{
	if (symbol.token == ARRAY)
	{
		return ((symbol.array.end - symbol.array.start + 1) * (symbol.type == INTEGER ? 4 : 8));
	}
	else if (symbol.isReference == true || symbol.type == INTEGER)
	{
		return 4;
	}
	else if (symbol.type == REAL)
	{
		return 8;
	}
	else
		return 0;
}

void SymbolTable::clearLocalSymbols()
{
	int index = 0;

	for (auto &element : symbolTable)
	{
		if (element.isGlobal)
		{
			index++;
		}
	}
	symbolTable.erase(symbolTable.begin() + index, symbolTable.end());
	localAddressTop = 0;
}

string tokenToString(int token)
{
	switch (token)
	{
	case LABEL:
		return "label";
	case VAR:
		return "variable";
	case NUM:
		return "number";
	case ARRAY:
		return "array";
	case INTEGER:
		return "integer";
	case REAL:
		return "real";
	case PROC:
		return "procedure";
	case FUN:
		return "function";
	case ID:
		return "id";
	default:
		return "null";
	}
}

void SymbolTable::dump()
{
	cout << "; Symbol table dump" << endl;
	int i = 0;

	for (auto &e : symbolTable)
	{
		if (e.token != ID)
		{
			cout << "; " << i++;

			if (e.isGlobal)
			{
				cout << " Global ";
			}
			else
			{
				cout << " Local ";
			}

			if (e.isReference)
			{
				cout << "reference variable " << e.name << " ";
				if (e.token == ARRAY)
				{
					cout << tokenToString(e.token) << " [" << e.array.start << ".." << e.array.end
						 << "] of ";
				}
				cout << tokenToString(e.type) << " offset=" << e.address << endl;
			}
			else if (e.token == NUM)
			{
				cout << tokenToString(e.token) << " " << e.name << " " << tokenToString(e.type) << endl;
			}
			else if (e.token == VAR)
			{
				cout << tokenToString(e.token) << " " << e.name << " " << tokenToString(e.type) << " offset="
					 << e.address << endl;
			}
			else if (e.token == ARRAY)
			{
				cout << "variable " << e.name << " array [" << e.array.start << ".." << e.array.end
					 << "] of " << tokenToString(e.type) << " offset=" << e.address << endl;
			}
			else if (e.token == PROC || e.token == LABEL)
			{
				cout << tokenToString(e.token) << " " << e.name << " " << endl;
			}
			else if (e.token == FUN)
			{
				cout << tokenToString(e.token) << " " << e.name << " " << tokenToString(e.type) << endl;
			}
		}
	}
}
