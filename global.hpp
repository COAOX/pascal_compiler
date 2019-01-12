#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>
#include <list>
#include <fstream>
#include <sstream>
#include <iostream>
#include "symbol.hpp"

#define LABEL 303
#define PLUS 304
#define MINUS 305
#define MUL 306
#define DIV 307
#define MOD 308
#define AND 309
#define EQ 210
#define NE 211
#define GE 212
#define LE 213
#define G 214
#define L 215
#define INTTOREAL 316
#define REALTOINT 317
#define PUSH 318
#define INCSP 319
#define CALL 320
#define RETURN 321
#define JUMP 322

using namespace std;

extern bool inGlobalScope;
extern int lineno;
extern ofstream outputStream;
extern FILE *yyin;
extern SymbolTable symbolTable;

//error
bool checkDeclaredVariable(int id);

//lexer
int yylex();
int yylex_destroy();

//parser
int yyparse();
void yyerror(char const *s);

//emitter
void generateAssignment(Symbol& symbol1, Symbol& symbol2);
string getVariableAddress(Symbol& symbol);
string getTypeSuffix(int type);
void castUp(Symbol& symbol1, Symbol& symbol2);
string getOperatorText(int op, int type);
void generateExpression(int op, Symbol symbol1, Symbol symbol2, Symbol result);
void generateRelopJump(int op, Symbol symbol1, Symbol symbol2, Symbol label);
void generateLabel(Symbol label);
void generateJump(Symbol label);
void writeToOutput(string str);
void writeToFile();