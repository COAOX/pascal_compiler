%{
	#include "global.hpp"

	using namespace std;

	int startOffsertParamtersFunProcHelper = 8;	// 8 dla proc 12 dla fun
	vector<int> parameterVector;

	void yyerror(char const* s);
%}

%token 	PROGRAM
%token 	BEGINN
%token 	END
%token 	VAR
%token 	INTEGER
%token  REAL
%token	ARRAY
%token 	OF
%token	FUN
%token 	PROC
%token	IF
%token	THEN
%token	ELSE
%token	DO
%token	WHILE
%token 	RELOP
%token 	MULOP
%token 	SIGN
%token 	ASSIGN
%token	OR
%token 	NOT
%token 	ID
%token 	NUM
%token 	NONE
%token 	DONE

%%

program:
    PROGRAM ID '(' start_identifiers ')' ';' declarations subprogram_declarations
        {
        }
    compound_statement
    '.'
        {
        }
    eof
	;

identifier_list:
    ID
        {
        }
	| identifier_list ',' ID
        {
        }
	;

declarations:
	declarations VAR identifier_list ':' type ';'
		{
		}
	| //empty
	;

type:
    INTEGER
	| REAL
	;

subprogram_declarations:
    subprogram_declarations subprogram_declaration ';'
	| //empty
	;

subprogram_declaration:
    subprogram_head declarations compound_statement
	;

subprogram_head:
    FUN ID
        {	
        }
    arguments
        {	
        }
    ':' standard_type
        {	
        }
    ';'
	| PROC ID
        { 	
        }
    arguments
        {	
        }
    ';'
	;

arguments:
    '(' parameter_list ')'
        {
        }
	| //empty
	;

parameter_list:
    identifier_list ':' type
        {	
        }
	| parameter_list ';' identifier_list ':' type
        {
        }
	;

compound_statement:
    BEGIN optional_statements END
	;

optional_statements:
    statement_list
	| //empty
	;

statement_list:
    statement
	| statement_list ';' statement
	;

statement:
    variable ASSIGN simple_expression
        {
        }
	| procedure_statement
	| compound_statement
	| IF expression
        {
        }
    THEN statement
        {
        }
    ELSE statement
        {
        }
	| WHILE
        {	
        }
    expression DO
        {
        }
    statement
        {	
        }
	;

variable:
    ID
        {
            checkSymbolExist($1);
            $$ = $1;
        }
	;

procedure_statement:
    ID
        {	
            writeToOutput("\tcall.i #" + $1.name);
        }
	| ID '(' expression_list ')'
        {	
        }
	;

expression_list:
    expression
        {
            parameterVector.push_back($1);
        }
	| expression_list ',' expression
        {
            parameterVector.push_back($3);
        }
	;

expression:
    simple_expression
        {
            $$ = $1;
        }
    | simple_expression RELOP simple_expression
        {
        }
	;

simple_expression:
    term
	| SIGN term
        {
        }
	| simple_expression SIGN term
        {
        }
	| simple_expression OR term
        {
        }
	;

term:
    factor
	| term MULOP factor
        {
        }
	;

factor:
    variable
        {	
            $$ = $1;
        }
	| ID '(' expression_list ')'
        {
        }
	| NUM
        {
            $$ = $1;
        }
	| '(' expression ')'
        {
            $$ = $2;
        }
	| NOT factor
			{	
			}
	;

eof:
		DONE
			{
				return 0;
			}
  ;

%%

void yyerror(char const *s)
{
	printf("Blad w linii %d: %s \n",lineno, s);
}
