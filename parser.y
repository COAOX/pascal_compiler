%{
	#include "global.hpp"
    #define YYDEBUG 1

	using namespace std;

	int startOffsertParamtersFunProcHelper = 8;	// 8 dla proc 12 dla fun
	vector<int> identifierVector;
    Array tempArrayInfo;
	void yyerror(char const* s);
    extern SymbolTable symbolTable;
%}

%token 	PROGRAM
%token 	BEGIN_
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
    PROGRAM ID '(' identifier_list ')' ';' declarations subprogram_declarations
        {
            writeToOutput("lab0:");
        }
    compound_statement
    '.'
        {
            writeToOutput("exit");
            writeToFile();
        }
    eof
	;

identifier_list:
    ID
        {
            checkDeclaredVariable($1);
            identifierVector.push_back($1);
        }
	| identifier_list ',' ID
        {
            checkDeclaredVariable($3);
            identifierVector.push_back($3);
        }
	;

declarations:
	declarations VAR identifier_list ':' type ';'
		{
            symbolTable.dump();
            for(auto &index : identifierVector)
            {
                Symbol& symbol = symbolTable[index];
                if ($5 == INTEGER)
                {
                    symbol.token = VAR;
                    symbol.type = INTEGER;
                    symbolTable.allocateNewVariable(symbol);
                }
                else if ($5 == REAL)
                {
                    symbol.token = VAR;
                    symbol.type = REAL;
                    symbolTable.allocateNewVariable(symbol);
                }
                else if ($5 == ARRAY)
                {
                    symbol.token = ARRAY;
                    symbol.type = tempArrayInfo.type;
                    symbol.array = tempArrayInfo;
                    symbolTable.allocateNewVariable(symbol);
                }
                else 
                {
                    yyerror("invalid type on declaration");
                }
            }
            identifierVector.clear();
		}
	|
	;

type:
    standard_type
	| ARRAY '[' NUM '.' '.' NUM ']' OF standard_type
			{
                $$ = ARRAY;
                tempArrayInfo.start = $3;
                tempArrayInfo.end = $6;
                tempArrayInfo.type = $9;
			}
	;

standard_type:
    INTEGER
	| REAL
	;


subprogram_declarations:
    subprogram_declarations subprogram_declaration ';'
	|
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
	|
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
    BEGIN_ optional_statements END
	;

optional_statements:
    statement_list
	|
	;

statement_list:
    statement
	| statement_list ';' statement
	;

statement:
    variable ASSIGN simple_expression
        {
            generateAssignment(symbolTable[$1],symbolTable[$3]);
        }
	| procedure_statement
	| compound_statement
	| IF expression
        {
            int beforeElse = symbolTable.insertLabel();
            int num = symbolTable.insertConst("0",INTEGER);
            generateExpression(EQ,symbolTable[$2],symbolTable[num],symbolTable[beforeElse]); //jump to else
            $2 = beforeElse;
        }
    THEN statement
        {
            int afterElse = symbolTable.insertLabel();
            generateJump(symbolTable[afterElse]); //jump out of conditional
            generateLabel(symbolTable[$2]); //else
            $5 = afterElse;
        }
    ELSE statement
        {
            generateLabel(symbolTable[$5]); //out of conditional
        }
	| WHILE
        {	
            int labelFinish = symbolTable.insertLabel();
            int labelStart = symbolTable.insertLabel();
            $$ = labelFinish;
            $1 = labelStart;
            generateLabel(symbolTable[labelStart]); //beginning of loop
        }
    expression DO
        {
            int zero = symbolTable.insertConst("0",INTEGER);
            generateExpression(EQ,symbolTable[$3],symbolTable[zero],symbolTable[$2]); //jump to after loop
        }
    statement
        {	
            generateJump(symbolTable[$1]); //jump to start loop
            generateLabel(symbolTable[$2]); //end of loop
        }
	;

variable:
    ID
        {
            checkDeclaredVariable($1);
            $$ = $1;
        }
    | ID '[' expression ']'
	;

procedure_statement:
    ID
        {	
            writeToOutput("\tcall.i #" + symbolTable[$1].name);
        }
	| ID '(' expression_list ')'
        {	
        }
	;

expression_list:
    expression
        {
            identifierVector.push_back($1);
        }
	| expression_list ',' expression
        {
            identifierVector.push_back($3);
        }
	;

expression:
    simple_expression
        {
            $$ = $1;
        }
    | simple_expression RELOP simple_expression
        {
            int labelCorrect = symbolTable.insertLabel();
			generateExpression($2, symbolTable[$1],symbolTable[$3],symbolTable[labelCorrect]);
			int result = symbolTable.insertTempSymbol(INTEGER);
			int incorrect = symbolTable.insertConst("0",INTEGER);
            generateAssignment(symbolTable[incorrect],symbolTable[result]);
			int labelDone = symbolTable.insertLabel();
			generateJump(symbolTable[labelDone]);
            generateLabel(symbolTable[labelCorrect]);
			int correct = symbolTable.insertConst("1",INTEGER);
            generateAssignment(symbolTable[correct],symbolTable[result]);
            generateLabel(symbolTable[labelDone]);
            $$ = result;
        }
	;

simple_expression:
    term
	| SIGN term
        {
            if ($1 == PLUS)
            {
                $$ = $2;
            }
            else
            {
                $$ = symbolTable.insertTempSymbol(symbolTable[$2].type);
                int zero = symbolTable.insertConst("0", symbolTable[$2].type);
                generateExpression($1,symbolTable[zero],symbolTable[$2],symbolTable[$$]);
            }
        }
	| simple_expression SIGN term
        {
            $$ = symbolTable.insertTempSymbol(symbolTable.pickType($1,$3));
            generateExpression($2, symbolTable[$1],symbolTable[$3],symbolTable[$$]);
        }
	| simple_expression OR term
        {
            $$ = symbolTable.insertTempSymbol(INTEGER);
            generateExpression(OR,symbolTable[$1],symbolTable[$3],symbolTable[$$]);
        }
	;

term:
    factor
	| term MULOP factor
        {
            $$ = symbolTable.insertTempSymbol(symbolTable.pickType($1,$3));
            generateExpression($2, symbolTable[$1],symbolTable[$3],symbolTable[$$]);
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
	printf("error on line %d: %s \n",lineno, s);
}
