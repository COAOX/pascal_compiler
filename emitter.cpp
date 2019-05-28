#include <iomanip>
#include "global.hpp"
#include "parser.hpp"
using namespace std;

extern ofstream outputStream;
extern SymbolTable symbolTable;
stringstream ss;

void generateAssignment(Symbol &left_side, Symbol &right_side)
{
     writeToOutput("\tasn" + getVariableAddress(right_side) + "," + getVariableAddress(left_side));
}

void generateExpression(int op, Symbol symbol1, Symbol symbol2, Symbol result)
{
    castUp(symbol1, symbol2);
    writeToOutput(getOperatorText(op, result.type) + getVariableAddress(symbol1) + ',' + getVariableAddress(symbol2) + ',' + getVariableAddress(result));
}

void generateRelopJump(int op, Symbol symbol1, Symbol symbol2, Symbol label)
{
    castUp(symbol1, symbol2);
    writeToOutput(getOperatorText(op, symbol1.type) + getVariableAddress(symbol1) + ',' + getVariableAddress(symbol2) + ",#" + label.name);
}

void generateLabel(Symbol label)
{
    writeToOutput("\tlabel\t"+label.name);
}

void generateJump(Symbol label)
{
    writeToOutput("\tgoto\t #" + label.name);
}

void generateFunction(Symbol function)
{
    cout << function.name;
    writeToOutput("\tlabel\t" + function.name);
    //writeToOutput("\tenter.i #__"); //come back and fill this in
}

void generateCall(Symbol function)
{
    writeToOutput(getOperatorText(CALL,INTEGER) + "#" + function.name);
}

void generatePush(Symbol symbol)
{
    writeToOutput(getOperatorText(PUSH,INTEGER) + getVariableAddress(symbol,'#'));
}

void generateArrayAddress(Symbol arrayBase, Symbol offset, Symbol result)
{
    writeToOutput(getOperatorText(PLUS, INTEGER) + getVariableAddress(arrayBase,'#') + ',' + getVariableAddress(offset) + ',' + getVariableAddress(result));
}

void fillEnter(int size)
{
    string stream = ss.str();
    ss.str("");
    stream.replace(stream.find("__"),2,to_string(size));
    writeToOutput(stream);
}

string getOperatorText(int op, int type)
{
    string result = "";
    switch (op)
    {
    case MINUS:
        result = "sub";
        break;
    case PLUS:
        result = "add";
        break;
    case MUL:
        result = "mul";
        break;
    case DIV:
        result = "div";
        break;
    case AND:
        result = "and";
        break;
    case OR:
        result = "or";
        break;
    case MOD:
        result = "mod";
        break;
    case EQ:
        result = "je";
        break;
    case NE:
        result = "jne";
        break;
    case LE:
        result = "jle";
        break;
    case GE:
        result = "jge";
        break;
    case G:
        result = "jg";
        break;
    case L:
        result = "jl";
        break;
    case PUSH:
        result = "push";
        break;
    case CALL:
        result = "call";
        break;
    }
    return '\t' + result;
}
void castUp(Symbol &symbol1, Symbol &symbol2)
{
    if (symbol1.type == INTEGER && symbol2.type == REAL)
    {
        int newVar = symbolTable.insertTempSymbol(REAL);
        writeToOutput("\tinttoreal.i\t" + getVariableAddress(symbol1) + ',' + getVariableAddress(symbolTable[newVar]));
        symbol1 = symbolTable[newVar];
    }
    else if (symbol1.type == REAL && symbol2.type == INTEGER)
    {
        int newVar = symbolTable.insertTempSymbol(REAL);
        writeToOutput("\tinttoreal.i\t" + getVariableAddress(symbol2) + ',' + getVariableAddress(symbolTable[newVar]));
        symbol2 = symbolTable[newVar];
    }
    else if (symbol1.type != symbol2.type)
    {
        yyerror("incompatible types in casting up");
    }
}

string getVariableAddress(Symbol &symbol, char op)
{
    string result = "";
    if (symbol.token == NUM)
    {
        result = "#" + symbol.name;
    }
    else if (symbol.token == VAR || symbol.token == ARRAY)
    {
        result += (op == '#' && !symbol.isReference) ? "#" : "";
        result += (symbol.isReference && op!='#') ? "*" : "";
        result += (!symbol.isGlobal) ? "BP" : "";
        result += (!symbol.isGlobal & symbol.address >= 0) ? "+" : "";
        result += to_string(symbol.address);
    }
    return result;
}

string getTypeSuffix(int type)
{
    if (type == REAL)
    {
        return ".r\t";
    }
    else if (type == INTEGER)
    {
        return ".i\t";
    }
    else
    {
        yyerror("invalid type in get type suffix");
        return "";
    }
}

void writeToOutput(string str)
{
    //cout << "\n" << str;
    ss << "\n"
       << str;
}

void writeToFile()
{
    outputStream.write(ss.str().c_str(), ss.str().size());
    ss.str(string()); //clear
}