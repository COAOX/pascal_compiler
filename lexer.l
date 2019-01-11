%{
	#include "global.hpp"
	#include "parser.hpp"

	int lineno = 1;
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

%%

[\t|" "]			{}
[\n]				{lineno++;}

{integer}			{yylval = INTEGER; return INTEGER;}
{real}				{yylval = REAL; return REAL;}

var 				{return VAR;}
program				{return PROGRAM;}
begin				{return BEGIN;}
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

{relop}				{yylval = getToken(yytext); return RELOP;}
{mulop}				{yylval = getToken(yytext); return MULOP;}
{sign}				{yylval = getToken(yytext); return SIGN;}
{assignop}			{return ASSIGN;}

{id}				{yylval = lookupIfExistAndInsert(yytext, ID, NONE); return ID;}
{digits}			{yylval = lookupIfExistAndInsert(yytext, NUM, INTEGER); return NUM;}
{num}				{yylval = lookupIfExistAndInsert(yytext, NUM, REAL); return NUM;}

<<EOF>>				{return DONE;}
.					{return *yytext;}

%%
