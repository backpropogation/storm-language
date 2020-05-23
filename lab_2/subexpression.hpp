/* Based on John Levine's book "flex&bison" */
#ifndef _SUBEXPRESSION_HPP
#define _SUBEXPRESSION_HPP

typedef enum
{
    typeInt,         /* Integer number */
    typeDouble,      /* Floating point number with double precision */
    typeChar, 		 /* Character type */
    typeBool,		 /* Logical type */
    typeIntArray,         /* Integer number Array*/
    typeDoubleArray,      /* Floating point number with double precision Array*/
    typeCharArray, 		  /* Character type Array*/
    typeBoolArray,		  /* Logical type Array*/
} SubexpressionValueTypeEnum;

#endif
