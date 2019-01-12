%{
	#include "global.hpp"
	#include "parser.hpp"

	int lineno = 1;
	int getToken(string value);

	extern SymbolTable symbolTable;
%}

%option noyywrap

letter				[a-zA-Z]
digit 				[0-9]
id					{letter}({letter}|{digit})*

digits				{digit}+
optional_fraction 	"."{digits}?
optional_exponent	[eE][+-]?{digits}
num					{digits}(optional_fraction){optional_exponent}?

relop				"="|"<>"|"<"|"<="|">="|">"
sign				"+"|"-"
mulop				"*"|"/"|"div"|"mod"|"and"
assignop			":="

integer				"integer"
real				"real"
procedure			"procedure"
function			"function"
array				"array"
of 					"of"

%%	

[\t|" "]			{}
[\r]				{lineno++;}

{integer}			{yylval = INTEGER; return INTEGER;}
{real}				{yylval = REAL; return REAL;}

var 				{return VAR;}
program				{return PROGRAM;}
begin				{return BEGIN_;}
end					{return END;}
not					{return NOT;}
or					{return OR;}
if					{return IF;}
then				{return THEN;}
else				{return ELSE;}
do					{return DO;}
while				{return WHILE;}

{function}			{return FUN;}
{procedure}			{return PROC;}
{array}				{return ARRAY;}
{of}				{return OF;}

{relop}				{yylval = getToken(yytext); return RELOP;}
{mulop}				{yylval = getToken(yytext); return MULOP;}
{sign}				{yylval = getToken(yytext); return SIGN;}
{assignop}			{return ASSIGN;}

{id}				{yylval = symbolTable.lookupLocalOrInsert(yytext, ID, NONE); cout << "accessing " << yytext << yylval << '\n'; return ID;}
{digits}			{yylval = symbolTable.lookupLocalOrInsert(yytext, NUM, INTEGER); return NUM;}
{num}				{yylval = symbolTable.lookupLocalOrInsert(yytext, NUM, REAL); return NUM;}

<<EOF>>				{return DONE;}
.					{return *yytext;}

%%

int getToken(string value) 
	{
		string strVal = value;
		if (strVal.compare("+") == 0) {
			return PLUS;
		}
		if (strVal.compare("-") == 0) {
			return MINUS;
		}
		if (strVal.compare("*") == 0) {
			return MUL;
		}
		if (strVal.compare("div") == 0 || strVal.compare("/") == 0) {
			return DIV;
		}
		if (strVal.compare("mod") == 0) {
			return MOD;
		}
		if (strVal.compare("and") == 0) {
			return AND;
		}
		if (strVal.compare("=") == 0) {
			return EQ;
		}
		if (strVal.compare(">=") == 0) {
			return GE;
		}
		if (strVal.compare("<=") == 0) {
			return LE;
		}
		if (strVal.compare("<>") == 0) {
			return NE;
		}
		if (strVal.compare(">") == 0) {
			return G;
		}
		if (strVal.compare("<") == 0) {
			return L;
		}
		return 0;
	}
