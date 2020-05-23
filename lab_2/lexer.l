%{
/*  Based on John Levine's book "flex&bison" */

#if defined _WIN32
#include <io.h>              // For isatty
#elif defined _WIN64
#include <io.h>              // For isatty
#endif

#ifdef MSVC
#define  isatty _isatty		// In VC isatty names as _isatty
#endif

#include <ctype.h>
#include "ast.hpp"
#include "simpl-lang.hpp"
#include "simpl-driver.hpp"

// Work around an incompatibility in flex (at least versions
// 2.5.31 through 2.5.33): it generates code that does
// not conform to C89.  See Debian bug 333231
// <http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=333231>.
#undef yywrap
#define yywrap() 1

// The location of the current token.
yy::location loc;

typedef yy::Parser::token token;
typedef yy::Parser::token_type token_type;

    /* By default yylex returns int, we use token_type.
       Unfortunately yyterminate by default returns 0, which is
       not of token_type.  */
#define yyterminate() return token::EOFILE
%}

%option noyywrap nounput noinput noyylineno

/* Exponential part of the floating point number */
EXP	([Ee][-+]?[0-9]+)

%{
// Code run each time a pattern is matched.
#define YY_USER_ACTION  loc.columns(yyleng);
%}

%%
%{
  // Code run each time yylex is called.
  loc.step();
%}
          /* Operator tokens */
\*|\/     { strcpy(yylval->s, yytext); return token::MULOPERATOR; }

\+        { return token::PLUS; }
\-        { return token::MINUS; }

"="       { return token::ASSIGN; }

          /* Punctuator tokens */
"{"       { return token::OPENBRACE; }
"}"       { return token::CLOSEBRACE; }
"["       { return token::OPENSQRBRACE; }
"]"       { return token::CLOSESQRBRACE; }
";"       { return token::SEMICOLON; }
","       { return token::COMMA; }
"("       { return token::OPENPAREN; }
")"       { return token::CLOSEPAREN; }

          /* Comparison and relation operator tokens */
">"  |
"<"  |
"!=" |
"==" |
">=" |
"<="      { strcpy(yylval->s, yytext); return token::RELOP; }

          /* keyword */
"if"      { return token::IF; }
"else"    { return token::ELSE; }
"int"     { return token::INT; }
"float"   { return token::FLOAT; }
"char"    { return token::CHAR; }
"bool"    { return token::BOOL; }
"do"      { return token::DO; }
"while"   { return token::WHILE; }
"for"     { return token::FOR; }
"break"   { return token::BREAK; }
"continue" { return token::CONTINUE; }
"return"  { return token::RETURN; }
"vox"     { return token::VOX; }
"wouf"    { return token::WOUF; }
"func"    { return token::FUNC; }
"main"    { return token::MAIN; }
"->"      { return token::FUNCRETURN; }

[[:alpha:]_][[:alnum:]_]*       { yylval->var = new std::string(yytext, yyleng);
                                  return token::VARIABLE;
                                }
0|[1-9][0-9]*        { yylval->i = atoi(yytext); return token::INTCONST; }

([0-9]*\.[0-9]+|[0-9]+\.){EXP}? |
[0-9]+{EXP}                        { yylval->d = atof(yytext); return token::NUMBER; }


[ \t]+ { loc.step(); }  /* white spaces skippng */
[\n]+  { loc.lines(yyleng); loc.step(); }


<<EOF>>     { return token::EOFILE; }
. {
    std::string tmp(yytext);
    driver.error(loc, "Magical mistery character " + tmp);
    return static_cast<token_type>(*yytext);
}
%%

void Simpl_driver::scan_begin()
{
  if (filename.empty() || filename == "-")
    yyin = stdin;
  else if (!(yyin = fopen(filename.c_str(), "r")))
  {
    error("cannot open " + filename + ": " + strerror(errno));
    exit(EXIT_FAILURE);
  }
}

void Simpl_driver::scan_end()
{
  fclose(yyin);
}

