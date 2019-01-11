#include "global.hpp"
#include "parser.hpp"

using namespace std;

int variablesCount = 0;
int labelsCount = 1;
vector<Symbol> SymbolTable;

int insert(string name, int token, int type) {
	Symbol symbol;
	symbol.name = name;
	symbol.type = type;
	symbol.isGlobal = inGlobalScope;
	symbol.isReference = false;
	symbol.address = 0;

	SymbolTable.push_back(symbol);
	return (int) (SymbolTable.size() - 1);
}

int insertTempSymbol(int type) {
	string name = "$t" + to_string(variablesCount++);
	int id = insert(name, VAR, type);
	SymbolTable[id].address = getSymbolAddress(name);
	return id;
}

int insertLabel() {
	string name = "lab" + to_string(labelsCount++);
	int id = insert(name, LABEL, NONE);
	return id;
}

void initSymbolTable() {
	Symbol lab0;
	lab0.name = ("lab0");
	lab0.isGlobal = true;
	lab0.isReference = false;
	lab0.token = LABEL;
	SymbolTable.push_back(lab0);
}

int lookup(string name) {
	int index = (int) (SymbolTable.size() - 1);

	for (; index >= 0; index--) {
		if (SymbolTable[index].name == name) {
			return index;
		}
	}
	return -1;
}

int lookupLocal(string name) {
	int index = (int) (SymbolTable.size() - 1);

	if (inGlobalScope) {
		for (; index >= 0; index--) {
			if (SymbolTable[index].name == name) {
				return index;
			}
		}
	} else {
		for (; index >= 0; index--) {
			if (!SymbolTable[index].isGlobal && SymbolTable[index].name == name) {
				return index;
			}
		}
	}
	return -1;
}

int lookupLocalOrInsert(string s, int token, int type) {
	int value = lookupLocal(s);

	if (value == -1) {
		value = insert(s, token, type);
	}
	return value;
}

int getSymbolAddress(string symbolName) {
	int address = 0;

	if (isGlobal) {
		for (auto &symbol : SymbolTable) {
			if (symbol.isGlobal && symbol.name != symbolName) {
				address += getSymbolSize(symbol);
			}
		}
	} else {
		for (auto &symbol : SymbolTable) {
			if (!symbol.isGlobal && symbol.address <= 0) {
				address -= getSymbolSize(symbol);
			}
		}
	}
	return address;
}

int getSymbolSize(Symbol symbol) {
		if (symbol.type == INTEGER) {
			return 4;
		} else if (symbol.type == REAL) {
			return 8;
		} 
        else return 0;
}

void clearLocalSymbols() {
	int index = 0;

	for (auto &element : SymbolTable) {
		if (element.isGlobal) {
			index++;
		}
	}
	SymbolTable.erase(SymbolTable.begin() + index, SymbolTable.end());
}