%{
/* Based on John Levine's book "flex&bison"*/
#include <cstdio>
#include <cstdlib>
#include <string>
#include <cstring>
#include <algorithm>
#include <fstream>
#include <iostream>

#include "ast.hpp"
#include "symtable.hpp"
#include "simpl-driver.hpp"
%}

%skeleton "lalr1.cc"
%require  "3.0"
%defines

/* set the parser's class identifier */
%define parser_class_name {Parser}
%define parse.assert

%code requires
{
  class Simpl_driver;
}

// The parsing context
%param { Simpl_driver& driver }

%locations
%initial-action
{
  // Initialize the initial location.
  @$.begin.filename = @$.end.filename = &driver.filename;
};

%define parse.trace
%define parse.error verbose

%code
{
#undef yyerror
#define yyerror driver.error

static std::string ErrorMessageVariableNotDeclared(std::string);
static std::string ErrorMessageVariableDoublyDeclared(std::string);

int g_LoopNestingCounter = 0;

static TSymbolTable* g_TopLevelUserVariableTable = CreateUserVariableTable(NULL);
static TSymbolTable* currentTable = g_TopLevelUserVariableTable;
}

%union
{
  NodeAST* a;
  double d;
  int i;
  std::string* var;
  char s[3];
}

/* declare tokens */
%token          EOFILE 0        "end of file"
%token <d>      NUMBER          "floating point double precision"
%token <i>      INTCONST        "integer"
%token <var>    VARIABLE        "name"
%token <s>      RELOP           "relop"
%token          PLUS            "plus"
%token          MINUS           "minus"
%token <s>      MULOPERATOR     "mulop"
%token          OPENBRACE       "{"
%token          CLOSEBRACE      "}"
%token          OPENSQRBRACE    "["
%token          CLOSESQRBRACE   "]"
%token          OPENPAREN       "("
%token          CLOSEPAREN      ")"
%token          ASSIGN          "="
%token          SEMICOLON       ";"
%token          COMMA           ","
%token          IF              "if"
%token          ELSE            "else"
%token          INT             "int"
%token          FLOAT           "float"
%token          CHAR            "char"
%token          BOOL            "bool"
%token          DO              "do"
%token          WHILE           "while"
%token          FOR             "for"
%token          BREAK           "break"
%token          CONTINUE        "continue"
%token          RETURN          "return"
%token          VOX             "vox"
%token          WOUF            "wouf"
%token          FUNCRETURN      "->"
%token          FUNC            "func"
%token          MAIN            "main"
%token IFX

%type <a> exp cond_stmt assignment statement compound_statement stmtlist stmtlist_tail prog declarations loop_stmt for_head while_head wouf vox func main_func type

%nonassoc IFX
%nonassoc ELSE

%right ASSIGN
%left RELOP
%left PLUS MINUS
%left MULOPERATOR
%right UMINUS

%start prog

%printer { yyoutput << $$; } <*>;

%destructor { delete $$; } VARIABLE
%%
/*------------------------------------------------------------*/
prog :
    stmtlist
        {
            if (driver.AST_dumping)
            {
                PrintAST($1, 0);
            }
            if (driver.XML_dumping)
            {
                std::ofstream xmlFile;
                xmlFile.open(driver.XML_dumping_path);
                printf("Write XML into \'%s\'\n", driver.XML_dumping_path.c_str());
                WriteXml($1, 0, xmlFile);
                xmlFile.close();
            }
            FreeAST($1);
            DestroyUserVariableTable(currentTable);
            driver.result = 0;
        }
;

stmtlist :
    statement stmtlist_tail
        {
            if ($2 == NULL)
                $$ = $1;
            else
                $$ = CreateNodeAST(typeList, "L", $1, $2);
        }
;

stmtlist_tail :
    %empty
        {
            $$ = NULL;
        }
    | stmtlist
        {
            $$ = $1;
        }
;

statement :
    assignment | cond_stmt | declarations | compound_statement | loop_stmt | wouf | vox | func | RETURN SEMICOLON
        {
            $$ = CreateControlFlowNode(typeJumpStatement, NULL, NULL, NULL);
        }
    | BREAK SEMICOLON
        {
            if (g_LoopNestingCounter <= 0)
                yyerror("'break' not inside loop");
            $$ = CreateControlFlowNode(typeJumpStatement, NULL, NULL, NULL);
        }
    | CONTINUE SEMICOLON
        {
            if (g_LoopNestingCounter <= 0)
                yyerror("'continue' not inside loop");
            $$ = CreateControlFlowNode(typeJumpStatement, NULL, NULL, NULL);
        }
;

compound_statement :
    OPENBRACE
        {
            currentTable = CreateUserVariableTable(currentTable);
        }
    stmtlist
    CLOSEBRACE
    {
        $$ = $3;
        HideUserVariableTable(currentTable);
        currentTable = currentTable->parentTable;
    }
;

/* ASSIGNMENT */
assignment :
    VARIABLE ASSIGN exp SEMICOLON
    {
        TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$1);
        if (NULL == var)
        {
            yyerror(ErrorMessageVariableNotDeclared(*$1));
        }
        else if ($3->valueType != var->table->data[var->index].valueType)
        {
            yyerror("warning - types incompatible in assignment");
        }
        $$ = CreateAssignmentNode(var, $3);
    }
;

/* DECLARATION */
declarations :
    INT VARIABLE ASSIGN exp SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeInt, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($4->valueType != var->table->data[var->index].valueType)
            {
                yyerror("warning - types incompatible in assignment");
                $$ = CreateAssignmentNode(var, CreateNumberNode(0));
            }
            else
            {
                $$ = CreateAssignmentNode(var, $4);
            }
        }
    | FLOAT VARIABLE ASSIGN exp SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeDouble, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($4->valueType != var->table->data[var->index].valueType)
            {
                yyerror("warning - types incompatible in assignment");
                $$ = CreateAssignmentNode(var, CreateNumberNode(0.0f));
            }
            else
            {
                $$ = CreateAssignmentNode(var, $4);
            }
        }
    | CHAR VARIABLE ASSIGN exp SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeChar, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($4->valueType != var->table->data[var->index].valueType)
            {
                yyerror("warning - types incompatible in assignment");
                $$ = CreateAssignmentNode(var, CreateNumberNode(0));
            }
            else
            {
                $$ = CreateAssignmentNode(var, $4);
            }
        }
    | BOOL VARIABLE ASSIGN exp SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeBool, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($4->valueType != var->table->data[var->index].valueType)
            {
                yyerror("warning - types incompatible in assignment");
                $$ = CreateAssignmentNode(var, CreateNumberNode(0));
            }
            else
            {
                $$ = CreateAssignmentNode(var, $4);
            }
        }
// arrays
    | INT VARIABLE ASSIGN INT OPENSQRBRACE exp CLOSESQRBRACE SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeIntArray, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($6->valueType != typeInt)
            {
                yyerror("warning - size of array must be const int");
                $$ = CreateAssignmentNode(var, CreateNumberNode(new int[0]));
            }
            else
            {
                $$ = CreateAssignmentNode(var, CreateNumberNode(new int[reinterpret_cast<TNumericValueNode *>($6)->iNumber]));
            }
        }
    | FLOAT VARIABLE ASSIGN FLOAT OPENSQRBRACE exp CLOSESQRBRACE SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeDoubleArray, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($6->valueType != typeInt)
            {
                yyerror("warning - size of array must be const int");
                $$ = CreateAssignmentNode(var, CreateNumberNode(new double[0]));
            }
            else
            {
                $$ = CreateAssignmentNode(var, CreateNumberNode(new double[reinterpret_cast<TNumericValueNode *>($6)->iNumber]));
            }
        }
    | CHAR VARIABLE ASSIGN CHAR OPENSQRBRACE exp CLOSESQRBRACE SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeCharArray, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($6->valueType != typeInt)
            {
                yyerror("warning - size of array must be const int");
                $$ = CreateAssignmentNode(var, CreateNumberNode(new char[0]));
            }
            else
            {
                $$ = CreateAssignmentNode(var, CreateNumberNode(new char[reinterpret_cast<TNumericValueNode *>($6)->iNumber]));
            }
        }
    | BOOL VARIABLE ASSIGN BOOL OPENSQRBRACE exp CLOSESQRBRACE SEMICOLON
        {
            TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, typeBoolArray, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            
            if ($6->valueType != typeInt)
            {
                yyerror("warning - size of array must be const int");
                $$ = CreateAssignmentNode(var, CreateNumberNode(new bool[0]));
            }
            else
            {
                $$ = CreateAssignmentNode(var, CreateNumberNode(new bool[reinterpret_cast<TNumericValueNode *>($6)->iNumber]));
            }
        }
  ;

/* IF */
cond_stmt:
    IF OPENPAREN exp CLOSEPAREN statement %prec IFX
        {
            $$ = CreateControlFlowNode(typeIfStatement, $3, $5, NULL);
        }
    | IF OPENPAREN exp CLOSEPAREN statement ELSE statement
        {
            $$ = CreateControlFlowNode(typeIfStatement, $3, $5, $7);
        }
;

/* LOOPS */
loop_stmt :
    while_head statement
        {
            $$ = CreateControlFlowNode(typeWhileStatement, $1, $2, NULL);
            --g_LoopNestingCounter;
        }
    | for_head statement
        {
            $$ = CreateControlFlowNode(typeWhileStatement, $1, $2, NULL);
            --g_LoopNestingCounter;
        }
    | DO statement while_head SEMICOLON
        {
            $$ = CreateControlFlowNode(typeWhileStatement, $3, $2, NULL);
            --g_LoopNestingCounter;
        }
;

while_head :
    WHILE OPENPAREN exp CLOSEPAREN
        {
            $$ = $3;
            ++g_LoopNestingCounter;
        }
;

for_head :
    FOR OPENPAREN exp SEMICOLON exp RELOP exp SEMICOLON exp CLOSEPAREN
        {
            $$ = $3;
            ++g_LoopNestingCounter;
        }
;

/* EXPRESSIONS */
exp :
    exp RELOP exp
        {
            if ($1->valueType != $3->valueType)
            {
                yyerror("warning - types in relop incompatible");
                if ($1->valueType == typeInt)
                    $$ = CreateNodeAST(typeBinaryOp, "+", CreateNodeAST(typeUnaryOp, "td", $1, NULL), $3);
                else
                    $$ = CreateNodeAST(typeBinaryOp, "+", $1, CreateNodeAST(typeUnaryOp, "td", $3, NULL));
            }
            else
                $$ = CreateNodeAST(typeBinaryOp, $2, $1, $3);
        }
    | exp PLUS exp
        {
            if ($1->valueType != $3->valueType)
            {
                yyerror("warning - types in addop incompatible");
                if ($1->valueType == typeInt)
                    $$ = CreateNodeAST(typeBinaryOp, "+", CreateNodeAST(typeUnaryOp, "td", $1, NULL), $3);
                else
                    $$ = CreateNodeAST(typeBinaryOp, "+", $1, CreateNodeAST(typeUnaryOp, "td", $3, NULL));
            }
            else
                $$ = CreateNodeAST(typeBinaryOp, "+", $1, $3);
        }
    | exp MINUS exp
        {
            if ($1->valueType != $3->valueType)
            {
                yyerror("warning - types in subop incompatible");
                if ($1->valueType == typeInt)
                    $$ = CreateNodeAST(typeBinaryOp, "+", CreateNodeAST(typeUnaryOp, "td", $1, NULL), $3);
                else
                $$ = CreateNodeAST(typeBinaryOp, "+", $1, CreateNodeAST(typeUnaryOp, "td", $3, NULL));
            }
            else
                $$ = CreateNodeAST(typeBinaryOp, "-", $1, $3);
        }
    | exp MULOPERATOR exp
        {
            if ($1->valueType != $3->valueType)
            {
                yyerror("warning - types in mulop incompatible");
                if ($1->valueType == typeInt)
                    $$ = CreateNodeAST(typeBinaryOp, "+", CreateNodeAST(typeUnaryOp, "td", $1, NULL), $3);
                else
                    $$ = CreateNodeAST(typeBinaryOp, "+", $1, CreateNodeAST(typeUnaryOp, "td", $3, NULL));
            }
            else
                $$ = CreateNodeAST(typeBinaryOp, $2, $1, $3);
        }
    | OPENPAREN exp CLOSEPAREN
        {
            $$ = $2;
        }
    | MINUS exp %prec UMINUS
        {
            $$ = CreateNodeAST(typeUnaryOp, "-", $2, NULL);
        }
    | NUMBER
        {
            $$ = CreateNumberNode($1);
        }
    | INTCONST
        {
            $$ = CreateNumberNode($1);
        }
    | VARIABLE
        {
            TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$1);
            if (NULL == var)
            {
                yyerror(ErrorMessageVariableNotDeclared(*$1));
            }
            $$ = CreateReferenceNode(var);
        }
;

/* INPUT */
vox :
    VOX OPENPAREN exp CLOSEPAREN SEMICOLON
        {
            $$ = CreateNodeAST(typeInput, "input", $3, NULL);
        }
;

/* OUTPUT */
wouf :
    WOUF OPENPAREN exp CLOSEPAREN SEMICOLON
        {
            $$ = CreateNodeAST(typeOutput, "output", $3, NULL);
        }
;

/* FUNCTIONS */
type:
    INT { $$ = CreateNumberNode(1);}
    | FLOAT {$$ = CreateNumberNode(1.1);}
    | CHAR {$$ = CreateNumberNode('1');}
    | BOOL {$$ = CreateNumberNode(true);}
    | INT OPENSQRBRACE CLOSESQRBRACE {$$ = CreateNumberNode(1);}
    | FLOAT OPENSQRBRACE CLOSESQRBRACE {$$ = CreateNumberNode(1.1);}
    | CHAR OPENSQRBRACE CLOSESQRBRACE {$$ = CreateNumberNode('1');}
    | BOOL OPENSQRBRACE CLOSESQRBRACE {$$ = CreateNumberNode(true);}
;

func_params :
    type VARIABLE 
    {
	    TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, $1->valueType, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
    }
    | func_params COMMA type VARIABLE 
    {
    	TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$4);
        if (NULL != var)
        {
            yyerror(ErrorMessageVariableDoublyDeclared(*$4));
        }
        else
        {
            bool kuku = InsertUserVariableTable(currentTable, *$4, $3->valueType, var);
            if (false == kuku)
                yyerror("Memory allocation or access error");
        }
    }
;

func :
    FUNC VARIABLE OPENPAREN  {
            currentTable = CreateUserVariableTable(currentTable);
        }
        CLOSEPAREN FUNCRETURN type  OPENBRACE stmtlist CLOSEBRACE
        {
        	TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, $7->valueType, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            $$ = CreateControlFlowNode(typeFunctionStatment, NULL, $9, NULL);
            HideUserVariableTable(currentTable);
        	currentTable = currentTable->parentTable;
        }
    | FUNC VARIABLE OPENPAREN {
            currentTable = CreateUserVariableTable(currentTable);
        } 
        func_params CLOSEPAREN FUNCRETURN type OPENBRACE stmtlist CLOSEBRACE
        {
        	TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
            if (NULL != var)
            {
                yyerror(ErrorMessageVariableDoublyDeclared(*$2));
            }
            else
            {
                bool kuku = InsertUserVariableTable(currentTable, *$2, $8->valueType, var);
                if (false == kuku)
                    yyerror("Memory allocation or access error");
            }
            $$ = CreateControlFlowNode(typeFunctionStatment, NULL, $10, NULL);
            HideUserVariableTable(currentTable);
        	currentTable = currentTable->parentTable;
        }
;

main_func :
    FUNC MAIN OPENPAREN CLOSEPAREN FUNCRETURN type compound_statement
        {
            $$ = CreateControlFlowNode(typeFunctionStatment, NULL, $7, NULL);
        }
;
/*------------------------------------------------------------*/
%%
void yy::Parser::error(const location_type& l, const std::string& m)
{
    driver.error(l, m);
}

static std::string ErrorMessageVariableNotDeclared(std::string name)
{
    std::string errorDeclaration = "warning - Variable " + name + " isn't declared";
    return errorDeclaration;
}

static std::string ErrorMessageVariableDoublyDeclared(std::string name)
{
    std::string errorDeclaration = "warning - Variable " + name + " is already declared";
        return errorDeclaration;
}

