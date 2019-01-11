#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <list>
#include <fstream>
#include <sstream>
#include <iostream>
#include "symbol.hpp"   

#define LABEL 		303
#define PLUS 		304
#define MINUS 		305
#define MUL 		306
#define DIV 		307
#define MOD 		308
#define AND 		309
#define EQ 			210
#define NE 			211
#define GE 			212
#define LE	 		213
#define G 			214
#define L 			215
#define INTTOREAL 	316
#define REALTOINT 	317
#define PUSH 		318
#define INCSP 		319
#define CALL 		320
#define RETURN 		321
#define JUMP 		322

using namespace std;

extern bool inGlobalScope;
extern int lineno;
extern ofstream outputStream;
extern FILE* yyin;
extern vector<Symbol> SymbolTable;

//error.c
bool checkSymbolExist(int);

//symbol.c
int insertTempSymbol(int);
int insertLabel();
int getSymbolAddress(string);
int getSymbolSize(Symbol);
string tokenToString(int);
void clearLocalSymbols();
void initSymbolTable();
int insert (string, int, int);
int insertNum(string, int);
int lookup(string);
int lookupIfExistAndInsert(string, int, int);
int lookupIfExist(string);
int lookupForFunction(string);

//lexer
int yylex();
int yylex_destroy();

//parser
int yyparse();
void yyerror(char const* s);
