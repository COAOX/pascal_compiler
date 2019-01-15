%{
	#include "global.hpp"
    #define YYDEBUG 1

	using namespace std;

	int parameterTop;
	vector<int> identifierVector;
    vector<Array> parameterTypes;
    Array tempArrayInfo;
	void yyerror(char const* s);
    extern SymbolTable symbolTable;
    vector<int> parameterVariables;
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
            writeToOutput("\texit");
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
                tempArrayInfo.start = std::stoi(symbolTable[$3].name);
                tempArrayInfo.end = std::stoi(symbolTable[$6].name);
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
    {
        //finished function declaration
        writeToOutput("\tleave");
        writeToOutput("\treturn");
        fillEnter(symbolTable.localAddressTop*-1);
        symbolTable.dump();
        symbolTable.clearLocalSymbols();
        inGlobalScope = true;
        parameterTop = 8;
    }
	;

subprogram_head:
    FUN ID
        {	
            checkDeclaredVariable($2);
            symbolTable[$2].token = FUN;
            inGlobalScope = false;
            parameterTop = 12; //old BP, retaddr, output
            generateFunction(symbolTable[$2]);
        }
    arguments
        {	
            symbolTable[$2].parameterList = parameterTypes;
            parameterTypes.clear();
        }
    ':' standard_type
        {	
            symbolTable[$2].type = $7;
            int ret = symbolTable.insert("return"+symbolTable[$2].name, VAR, $7);
            symbolTable[ret].isReference = true;
            symbolTable[ret].address = 8;
        }
    ';'
	| PROC ID
        { 	
            checkDeclaredVariable($2);
            symbolTable[$2].token = PROC;
            inGlobalScope = false;
            parameterTop = 8;
            generateFunction(symbolTable[$2]);
        }
    arguments
        {	
            symbolTable[$2].parameterList = parameterTypes;
            parameterTypes.clear();
        }
    ';'
	;

arguments:
    '(' parameter_list ')'
        {
            std::reverse(parameterVariables.begin(),parameterVariables.end()); //parameters are saved in memory in reverse order
            for (auto& argument : parameterVariables)
            {
                symbolTable[argument].address = parameterTop;
                parameterTop += 4; //reference int every time
            }
            parameterVariables.clear();
        }
	|
	;

parameter_list:
    identifier_list ':' type
        {	
            for (auto &index : identifierVector)
            {
                symbolTable[index].isReference = true;
                cout << symbolTable[index].name <<  index;
                
                if ($3 == ARRAY)
                {
                    symbolTable[index].token = ARRAY;
                    symbolTable[index].array = tempArrayInfo;
                    symbolTable[index].type = tempArrayInfo.type;
                }
                else
                {
                    symbolTable[index].token = VAR;
                    symbolTable[index].type = $3;
                    //for ease of trasnport array is used as a type transporter
                    tempArrayInfo.type = $3;
                    tempArrayInfo.start = -1;
                    tempArrayInfo.end = -1;
                }
                parameterTypes.push_back(tempArrayInfo);
                parameterVariables.push_back(index);
            }
            identifierVector.clear();
            symbolTable.dump();
        }
	| parameter_list ';' identifier_list ':' type
        {
            for (auto &index : identifierVector)
            {
                symbolTable[index].isReference = true;
                if ($5 == ARRAY)
                {
                    symbolTable[index].token = ARRAY;
                    symbolTable[index].array = tempArrayInfo;
                    symbolTable[index].type = tempArrayInfo.type;
                }
                else
                {
                    symbolTable[index].token = VAR;
                    symbolTable[index].type = $5;
                    //for ease of trasnport array is used as a type transporter
                    tempArrayInfo.type = $5;
                    tempArrayInfo.start = -1;
                    tempArrayInfo.end = -1;
                }
                parameterTypes.push_back(tempArrayInfo);
                parameterVariables.push_back(index);
            }
            identifierVector.clear();      
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
            generateRelopJump(EQ,symbolTable[$2],symbolTable[num],symbolTable[beforeElse]); //jump to else
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
            generateRelopJump(EQ,symbolTable[$3],symbolTable[zero],symbolTable[$2]); //jump to after loop
        }
    statement
        {	
            generateJump(symbolTable[$1]); //jump to start loop
            generateLabel(symbolTable[$2]); //end of loop
        }
	;

variable:
    ID
    | ID '[' expression ']'
        {
            if (symbolTable[$3].type == REAL)
            {
                yyerror("real-typed subscript");
            }
            Symbol& arrayBase = symbolTable[$1];
            int subscript = symbolTable.insertTempSymbol(INTEGER);
            int start = symbolTable.insertConst(to_string(arrayBase.array.start),INTEGER);
            generateExpression(MINUS,symbolTable[$3],symbolTable[start],symbolTable[subscript]);

            int elementSize = symbolTable.insertConst(
                (arrayBase.array.type == REAL? "8":"4"),INTEGER
            );

            generateExpression(MUL,symbolTable[subscript],symbolTable[elementSize],symbolTable[subscript]);

            int elementAddress = symbolTable.insertTempSymbol(INTEGER);

            generateArrayAddress(arrayBase,symbolTable[subscript],symbolTable[elementAddress]);

            symbolTable[elementAddress].isReference = true;
            symbolTable[elementAddress].type = arrayBase.array.type;
            $$ = elementAddress;
        }
	;

procedure_statement:
    ID
        {	
            checkDeclaredVariable($1);
            Symbol& symbol = symbolTable[$1];
            if (symbol.token == FUN || symbol.token == PROC)
            {
                if (symbol.parameterList.size()>0)
                {
                    yyerror("not enough parameters");
                }
                else
                {
                    generateCall(symbol);
                }
            }
            else 
            {
                yyerror("not a procedure");
            }
        }
	| ID '(' expression_list ')'
        {	
            if ($1 == symbolTable.lookup("read"))
            {
                for (auto& index : identifierVector)
                {
                    writeToOutput("\tread" + getTypeSuffix(symbolTable[index].type) + getVariableAddress(symbolTable[index]));
                }
            }
            else if ($1 == symbolTable.lookup("write"))
            {
                for (auto& index : identifierVector)
                {
                    writeToOutput("\twrite" + getTypeSuffix(symbolTable[index].type) + getVariableAddress(symbolTable[index]));
                }
            }
            else
            {
                checkDeclaredVariable($1);
                Symbol& func = symbolTable[$1];

                if (func.token == FUN)
                {
                    $$ = passParameters(func);
                }
                else if (func.token == PROC)
                {
                    passParameters(func);
                }
                else
                {
                    yyerror("no such function");
                }
            }
            identifierVector.clear();
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
    | simple_expression RELOP simple_expression
        {
            int labelCorrect = symbolTable.insertLabel();
			generateRelopJump($2, symbolTable[$1],symbolTable[$3],symbolTable[labelCorrect]);
			int result = symbolTable.insertTempSymbol(INTEGER);
			int incorrect = symbolTable.insertConst("0",INTEGER);
            generateAssignment(symbolTable[result],symbolTable[incorrect]);
			int labelDone = symbolTable.insertLabel();
			generateJump(symbolTable[labelDone]);
            generateLabel(symbolTable[labelCorrect]);
			int correct = symbolTable.insertConst("1",INTEGER);
            generateAssignment(symbolTable[result],symbolTable[correct]);
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
        //can be a function because pascal
        int temp = $1;
        Symbol& symbol = symbolTable[temp];
        if (symbol.token == FUN)
        {
            if (symbol.parameterList.size()>0)
            {
                yyerror("not enough arguments");
            }
            temp = symbolTable.insertTempSymbol(symbol.type);
            generatePush(symbolTable[temp]);
            generateCall(symbolTable[$1]);
            writeToOutput("\tincsp.i\t#4");            
        }
        else if (symbol.token == PROC)
        {
            yyerror("no return from procedure");
        }
        $$ = temp;
    }
	| ID '(' expression_list ')'
        {
            checkDeclaredVariable($1);
            Symbol& func = symbolTable[$1];
            if(func.token == FUN)
            {
                $$ = passParameters(func);
            }
            else if (func.token == PROC)
            {
                yyerror("no return from procedure");
            }
            else 
            {
                yyerror("no such function");
            }
        }
	| NUM
	| '(' expression ')'
        {
            $$ = $2;
        }
	| NOT factor
			{	
                int labelZero = symbolTable.insertLabel();
                int zero = symbolTable.insertConst("0",INTEGER);
                generateRelopJump(EQ,symbolTable[zero],symbolTable[$2],symbolTable[labelZero]);

                int result = symbolTable.insertTempSymbol(INTEGER);
                generateAssignment(symbolTable[result],symbolTable[zero]);

                int finish = symbolTable.insertLabel();
                generateJump(symbolTable[finish]);
                generateLabel(symbolTable[labelZero]);

                int notZero = symbolTable.insertConst("1",INTEGER);
                generateAssignment(symbolTable[result],symbolTable[notZero]);
                generateLabel(symbolTable[finish]);
                $$ = result;
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

int passParameters(Symbol& func)
{
    if (identifierVector.size() != func.parameterList.size())
    {
        yyerror("not enough arguments!");
    }
    int incspCount = 0;
    for (int i = 0; i < identifierVector.size(); i++)
    {
        int type = func.parameterList[i].type;
        int index = identifierVector[i];
        if (symbolTable[index].token == NUM)
        {
            int newindex = symbolTable.insertTempSymbol(type);
            generateAssignment(symbolTable[newindex],symbolTable[index]);
            index = newindex;
        }
        if (type != symbolTable[index].type)
        {
            yyerror("type mismatch in function parameters");
        }

        generatePush(symbolTable[index]);
        incspCount += 4;
    }
    int index = 0;

    if (func.token == FUN)
    {
        index = symbolTable.insertTempSymbol(func.type);
        generatePush(symbolTable[index]);
        incspCount += 4;
    }
    identifierVector.clear();
    generateCall(func);
    writeToOutput("\tincsp.i\t#" + to_string(incspCount));
    return index;
}