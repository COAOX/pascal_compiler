#include "global.hpp"

using namespace std;

bool checkDeclaredVariable(int id)
{
    if (id == -1)
    {
        yyerror("undeclared variable");
        return true;
    }
    else
    {
        return false;
    }
}