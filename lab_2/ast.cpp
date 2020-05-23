/*
* AST implementation
* Based on John Levine's book "flex&bison"
*/
#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <cstring>
#include <cmath>
#include <iostream>
#include <fstream>
#include <sstream>

#include "ast.hpp"

NodeAST* CreateNodeAST(NodeTypeEnum nodetype, const char* opValue, NodeAST* left, NodeAST* right)
{
  NodeAST* a;
  try
  {
    a = new NodeAST;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }
  a->nodetype = nodetype;
  strcpy(a->opValue, opValue);
  a->valueType = left->valueType;
  a->left = left;
  a->right = right;
  return a;
}

NodeAST* CreateNumberNode(double doubleValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeDouble;
  a->dNumber = doubleValue;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(int integerValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeInt;
  a->iNumber = integerValue;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(char charValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeChar;
  a->cNumber = charValue;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(bool boolValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeBool;
  a->bNumber = boolValue;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(double* doubleArrayValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeDoubleArray;
  a->dArrayNumber = doubleArrayValue;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(int* integerArrayValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeIntArray;
  a->iArrayNumber = integerArrayValue;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(char* charArrayValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeCharArray;
  a->cArrayNumber = charArrayValue;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateNumberNode(bool* boolArrayValue)
{
  TNumericValueNode* a;
  try
  {
    a = new TNumericValueNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeConst;
  a->valueType = typeBoolArray;
  a->bArrayNumber = boolArrayValue;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateControlFlowNode(NodeTypeEnum nodetype, NodeAST* condition,
			      NodeAST* trueBranch, NodeAST* elseBranch
			      )
{
  TControlFlowNode* a;
  try
  {
    a = new TControlFlowNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = nodetype;
  a->condition = condition;
  a->trueBranch = trueBranch;
  a->elseBranch = elseBranch;
  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateReferenceNode(TSymbolTableElementPtr symbol)
{
  TSymbolTableReference* a;
  try
  {
    a = new TSymbolTableReference;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }
  a->nodetype = typeIdentifier;
  a->variable = symbol;
  a->valueType = symbol->table->data[symbol->index].valueType;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST* CreateAssignmentNode(TSymbolTableElementPtr symbol, NodeAST* rightValue)
{
  TAssignmentNode* a;
  try
  {
    a = new TAssignmentNode;
  }
  catch (std::bad_alloc& ba)
  {
    perror("out of space");
    exit(0);
  }

  a->nodetype = typeAssignmentOp;
  a->variable = symbol;
  a->value = rightValue;
  
  return reinterpret_cast<NodeAST *>(a);
}

void FreeAST(NodeAST* a)
{
  if(NULL == a)
    return;
  switch(a->nodetype)
  {
  /* a pair of subtrees */
  case typeBinaryOp:
  case typeList:
    FreeAST(a->right);

    /* the only subtree */
  case typeUnaryOp:
  case typeInput:
  case typeOutput:
    FreeAST(a->left);

    /* Terminal node */
  case typeConst:
  case typeIdentifier:
  case typeJumpStatement:
  case typeFunctionStatment:
    break;
  case typeAssignmentOp:
    delete ((TAssignmentNode *)a)->value;
    break;
  case typeIfStatement:
  case typeWhileStatement:
    delete ((TControlFlowNode *)a)->condition;
    if( ((TControlFlowNode *)a)->trueBranch)
	  FreeAST( ((TControlFlowNode *)a)->trueBranch);
    if( ((TControlFlowNode *)a)->elseBranch)
	  FreeAST( ((TControlFlowNode *)a)->elseBranch);
    break;

  default: std::cout << "internal error: free bad node " << a->nodetype << std::endl;
  }	  
  
  delete a; /* Free the node itself */
}


void WriteXml(NodeAST *a, int level, std::ofstream &xml)
{
    try
    {
        if (a == NULL)
        {
            return;
        }

        switch (a->nodetype)
        {

            case typeConst:
                switch (a->valueType)
                {
                    case typeInt:
                        xml << std::string(2 * (level), ' ') << "<value name=\"INT\">" << ((TNumericValueNode *)a)->iNumber << "</value>\n";
                        break;
                    case typeDouble:
                        xml << std::string(2 * (level), ' ') << "<value name=\"DOUBLE\">" << ((TNumericValueNode *)a)->dNumber << "</value>\n";
                        break;
                    case typeChar:
                        xml << std::string(2 * (level), ' ') << "<value name=\"STRING\">" << (((TNumericValueNode *)a)->cNumber) << "</value>\n";
                        break;
                    case typeBool:
                        xml << std::string(2 * (level), ' ') << "<value name=\"BOOL\">" << ((TNumericValueNode *)a)->bNumber << "</value>\n";
                        break;
                    case typeIntArray:
                        xml << std::string(2 * (level), ' ') << "<value name=\"INT ARRAY\">" << ((TNumericValueNode *)a)->iArrayNumber << "</value>\n";
                        break;
                    case typeDoubleArray:
                        xml << std::string(2 * (level), ' ') << "<value name=\"DOUBLE\">" << ((TNumericValueNode *)a)->dArrayNumber << "</value>\n";
                        break;
                    case typeCharArray:
                        xml << std::string(2 * (level), ' ') << "<value name=\"STRING\">" << *(((TNumericValueNode *)a)->cArrayNumber) << "</value>\n";
                        break;
                    case typeBoolArray:
                        xml << std::string(2 * (level), ' ') << "<value name=\"BOOL\">" << ((TNumericValueNode *)a)->bArrayNumber << "</value>\n";
                        break;
                        
                    default:
                        break;
                }

            case typeJumpStatement:
                xml << std::string(2 * (level), ' ') << "<value name=\"JUMP\">" << "</value>\n";
                break;

            case typeIdentifier:
            {
                TSymbolTableElementPtr tmp = ((TSymbolTableReference *)a)->variable;
                std::string name = "";
                if (NULL != tmp)
                {
                    name = *(tmp->table->data[tmp->index].name);
                }
                else
                {
                    name = "(bad reference)";
                }

                xml << std::string(2 * (level), ' ') << "<value name=\"VARIABLE\">" << name << "</value>\n";
                return;
            }
            
            /* binary operator */
            case typeBinaryOp:
                xml << std::string(2 * level, ' ') << "<node type=\"binary_op\">\n";
                xml << std::string(2 * (level + 1), ' ') << "<value name=\"OP\">" << a->opValue << "</value>\n";

                WriteXml(a->left, level + 1, xml);
                WriteXml(a->right, level + 1, xml);

                xml << std::string(2 * level, ' ') << "</node>\n";
                
                break;

            /* Expression or statement list */
            case typeList:
                xml << std::string(2 * level, ' ') << "<node type=\"stmt_list\">\n";

                WriteXml(a->left, level + 1, xml);
                WriteXml(a->right, level + 1, xml);

                xml << std::string(2 * level, ' ') << "</node>\n";
                break;

            /* unary arithmetice operator */
            case typeUnaryOp:
                xml << std::string(2 * level, ' ') << "<node type=\"UNOP\">\n";
                xml << std::string(2 * (level + 1), ' ') << "<value name=\"OP\">" << a->opValue << "</value>\n";

                WriteXml(a->left, level + 1, xml);

                xml << std::string(2 * level, ' ') << "</node>\n";

                break;

            /* Assignment node */
            case typeAssignmentOp:
            {
                TSymbolTableElementPtr tmp = ((TAssignmentNode *)a)->variable;

                xml << std::string(2 * (level), ' ') << "<value name=\"OP\">" << "=" << "</value>\n";

                if (NULL != tmp)
                {
                    xml << std::string(2 * (level), ' ') << "<value name=\"VARIABLE\">" << *(tmp->table->data[tmp->index].name) << "</value>\n";
                }
                else
                {
                    xml << std::string(2 * (level), ' ') << "<value name=\"VARIABLE\">" << "(bad reference)" << "</value>\n";
                }
                WriteXml(((TAssignmentNode *)a)->value, level, xml);
                return;
            }

            case typeIfStatement:
                xml << std::string(2 * level, ' ') << "<node type=\"IF\">\n";
                xml << std::string(2 * level, ' ') << "<node type=\"CONDITION\" >\n";
                WriteXml(((TControlFlowNode *)a)->condition, level, xml);
                xml << std::string(2 * level, ' ') << "</node>\n";

                if (((TControlFlowNode *)a)->trueBranch)
                {
                    xml << std::string(2 * level, ' ') << "<node type=\"IF_TRUE\" >\n";
                    WriteXml(((TControlFlowNode *)a)->trueBranch, level + 1, xml);
                    xml << std::string(2 * level, ' ') << "</node>\n";
                }

                if (((TControlFlowNode *)a)->elseBranch)
                {
                    xml << std::string(2 * level, ' ') << "<node type=\"IF_FALSE\" >\n";
                    WriteXml(((TControlFlowNode *)a)->elseBranch, level + 1, xml);
                    xml << std::string(2 * level, ' ') << "</node>\n";
                }
                xml << std::string(2 * level, ' ') << "</node>\n";

                break;

            case typeWhileStatement:
                xml << std::string(2 * level, ' ') << "<node type=\"LOOP\">\n";
                xml << std::string(2 * level, ' ') << "<node type=\"CONDITION\">\n";
                WriteXml(((TControlFlowNode *)a)->condition, level, xml);
                xml << std::string(2 * level, ' ') << "</node>\n";

                if (((TControlFlowNode *)a)->trueBranch)
                {
                    xml << std::string(2 * level, ' ') << "<node type=\"LOOP_BODY\">\n";
                    WriteXml(((TControlFlowNode *)a)->trueBranch, level + 1, xml);
                    xml << std::string(2 * level, ' ') << "</node>\n";
                }
                xml << std::string(2 * level, ' ') << "</node>\n";
                
                break;
            
            case typeInput:
                xml << std::string(2 * level, ' ') << "<node type=\"INPUT\">\n";
                WriteXml(a->left, level + 1, xml);
                xml << std::string(2 * level, ' ') << "</node>\n";
                break;
            
            case typeOutput:
                xml << std::string(2 * level, ' ') << "<node type=\"OUTPUT\">\n";
                WriteXml(a->left, level + 1, xml);
                xml << std::string(2 * level, ' ') << "</node>\n";
                break;
            
            case typeReturn:
                xml << std::string(2 * level, ' ') << "<node type=\"RETURN\">" << "</node>\n";
                break;
            
            case typeFunctionStatment:
                xml << std::string(2 * level, ' ') << "<node type=\"FUNC\">\n";
                WriteXml(((TControlFlowNode *)a)->trueBranch, level + 1, xml);
                xml << std::string(2 * level, ' ') << "</node>\n";
                break;
        }
    }
    catch (const std::exception &e) {}

    return;
}

/* AST dump */
void PrintAST(NodeAST* a, int level)
{
  std::cout << std::string (2 * level, ' '); /* indent to this level */
  ++level;

  if (NULL == a)
  {
    std::cout << "NULL" << std::endl;
    return;
  }

  switch(a->nodetype)
  {
    /* Numeric literal node */
  case typeConst:
    if(typeDouble == ((TNumericValueNode *)a)->valueType)
      std::cout << "dnumber " << ((TNumericValueNode *)a)->dNumber << std::endl;
    else if(typeInt == ((TNumericValueNode *)a)->valueType)
      std::cout << "inumber " << ((TNumericValueNode *)a)->iNumber << std::endl;
    else if(typeChar == ((TNumericValueNode *)a)->valueType)
      std::cout << "cnumber " << ((TNumericValueNode *)a)->cNumber << std::endl;
    else if(typeBool == ((TNumericValueNode *)a)->valueType)
      std::cout << "bnumber " << ((TNumericValueNode *)a)->bNumber << std::endl;
    else if(typeDoubleArray == ((TNumericValueNode *)a)->valueType)
      std::cout << "darraynumber " << ((TNumericValueNode *)a)->dArrayNumber << std::endl;
    else if(typeIntArray == ((TNumericValueNode *)a)->valueType)
      std::cout << "iarraynumber " << ((TNumericValueNode *)a)->iArrayNumber << std::endl;
    else if(typeCharArray == ((TNumericValueNode *)a)->valueType)
      std::cout << "carraynumber " << ((TNumericValueNode *)a)->cArrayNumber << std::endl;
    else if(typeBoolArray == ((TNumericValueNode *)a)->valueType)
      std::cout << "barraynumber " << ((TNumericValueNode *)a)->bArrayNumber << std::endl;
    else
      std::cout << "bad constant" << std::endl;
    break;

  case typeJumpStatement:
    std::cout << "goto" << std::endl;
    break;

  /* Symtable reference node */
  case typeIdentifier:
  {
    TSymbolTableElementPtr tmp = ((TSymbolTableReference *)a)->variable;
    std::cout << "ref ";
    if (NULL != tmp)
      std::cout << *(tmp->table->data[tmp->index].name);
    else
      std::cout << "(bad reference)";
    std::cout << std::endl;
  }
  break;

    /* Expression node */
  case typeList:
  case typeBinaryOp:
    std::cout << "binop " << a->opValue << std::endl;
    PrintAST(a->left, level);
    PrintAST(a->right, level);
    return;

  /* Unary operator node */
  case typeUnaryOp: 
    std::cout << "unop " << a->opValue << std::endl;
    PrintAST(a->left, level);
    return;
  case typeInput:
    std::cout << "vox" << std::endl;
    PrintAST(a->left, level);
    return;
  case typeOutput:
    std::cout << "wouf" << std::endl;
    PrintAST(a->left, level);
    return;
  case typeReturn:
    std::cout << "return Expression" << std::endl;
    PrintAST(a->left, level);
    return;
    /* Assignment node */
  case typeAssignmentOp:
  {
    TSymbolTableElementPtr tmp = ((TAssignmentNode *)a)->variable;
    std::cout << "= ";
    if (NULL != tmp)
      std::cout << *(tmp->table->data[tmp->index].name);
    else
      std::cout << "(bad reference)";
    std::cout << std::endl;
    PrintAST( ((TAssignmentNode *)a)->value, level);
    return;
  }
  /* Control flow node - if */
  case typeIfStatement:
    std::cout << "flow - if" << std::endl;
    PrintAST( ((TControlFlowNode *)a)->condition, level);
    if( ((TControlFlowNode *)a)->trueBranch)
    {
      std::cout << std::string (2 * level, ' ');
      std::cout << "true-branch" << std::endl;
      PrintAST( ((TControlFlowNode *)a)->trueBranch, level + 1);
    }
    if( ((TControlFlowNode *)a)->elseBranch)
    {
      std::cout << std::string (2 * level, ' ');
      std::cout << "false-branch" << std::endl;
      PrintAST( ((TControlFlowNode *)a)->elseBranch, level + 1);
    }
    return;
    /* Control flow node - func */
  case typeFunctionStatment:
    std::cout << "flow - func" << std::endl;
    PrintAST( ((TControlFlowNode *)a)->trueBranch, level);
    return;

  /* Control flow node - while */
  case typeWhileStatement:
    std::cout << "flow - while" << std::endl;
    PrintAST( ((TControlFlowNode *)a)->condition, level);
    if( ((TControlFlowNode *)a)->trueBranch)
    {
      std::cout << std::string (2 * level, ' ');
      std::cout << "loop-body" << std::endl;
      PrintAST( ((TControlFlowNode *)a)->trueBranch, level + 1);
    }
    return;
		      
  default: std::cout << "bad node " << a->nodetype << std::endl;
    return;
  }
}
