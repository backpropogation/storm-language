/* Based on John Levine's book "flex&bison" */

#ifndef _ABSTRACT_SYNTAX_TREE_HPP
#define _ABSTRACT_SYNTAX_TREE_HPP

#include <string>
#include "subexpression.hpp"

typedef enum
{
    typeBinaryOp,          /* binary operator */
    typeUnaryOp,           /* unary arithmetice operator */
    typeAssignmentOp,      /* unary assignment operator */
    typeConst,             /* numeric literal */
    typeIdentifier,        /* variable name */
    typeIfStatement,       /* IfStatement */
    typeWhileStatement,    /* WhileStatement */
    typeJumpStatement,     /* Break or Continue statement */
    typeList,              /* Expression or statement list */
    typeInput,             /* Input*/
    typeOutput,            /* Output*/
    typeReturn,            /* ReturnExpresion */
    typeFunctionStatment   /* FunctionStatment */
} NodeTypeEnum;


/* AST node declaration */
/* Each node has to have a given type attribute */

typedef struct TAbstractSyntaxTreeNode
{
  NodeTypeEnum nodetype;
  SubexpressionValueTypeEnum valueType;
  char opValue[3];
  struct TAbstractSyntaxTreeNode* left;
  struct TAbstractSyntaxTreeNode* right;
} NodeAST;

typedef struct
{
  NodeTypeEnum nodetype;        /* IfStatement or WhileStatement node */
  NodeAST* condition;  /* Condition expression */
  NodeAST* trueBranch; /* true branch statement */
  NodeAST* elseBranch; /* (optional) false branch statement */
} TControlFlowNode;

typedef struct
{
  NodeTypeEnum nodetype;			/* Type K */
  SubexpressionValueTypeEnum valueType;
  union
  {
    int    iNumber;
    double dNumber;
    char   cNumber;
    bool   bNumber;
    int*    iArrayNumber;
    double* dArrayNumber;
    char*   cArrayNumber;
    bool*   bArrayNumber;
  };
} TNumericValueNode;

#ifndef _SYMBOL_TABLE_HPP
#include "symtable.hpp"
#endif

typedef struct
{
  NodeTypeEnum nodetype;
  SubexpressionValueTypeEnum valueType;
  TSymbolTableElementPtr variable;
} TSymbolTableReference;

typedef struct
{
  NodeTypeEnum nodetype;
  TSymbolTableElementPtr variable;
  NodeAST* value;
} TAssignmentNode;

/* AST procedures declaration */
NodeAST* CreateNodeAST(NodeTypeEnum cmptype, const char* opValue,
					   NodeAST* left, NodeAST* right);
NodeAST* CreateNumberNode(double doubleValue);
NodeAST* CreateNumberNode(int integerValue);
NodeAST* CreateNumberNode(bool boolValue);
NodeAST* CreateNumberNode(char charValue);
NodeAST* CreateNumberNode(double* doubleArrayValue);
NodeAST* CreateNumberNode(int* integerArrayValue);
NodeAST* CreateNumberNode(bool* boolArrayValue);
NodeAST* CreateNumberNode(char* charArrayValue);


NodeAST* CreateControlFlowNode(NodeTypeEnum Nodetype, NodeAST* condition,
                               NodeAST* trueBranch, NodeAST* elseBranch
                              );
NodeAST* CreateReferenceNode(TSymbolTableElementPtr symbol);
NodeAST* CreateAssignmentNode(TSymbolTableElementPtr symbol, NodeAST* rightValue);

/* Freeing AST node from memory space */
void FreeAST(NodeAST *);

void WriteXml(NodeAST *a, int level, std::ofstream &xml);
/* AST node dump */
void PrintAST(NodeAST* aTree, int level);

#endif
