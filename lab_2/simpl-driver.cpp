#include "ast.hpp"
#include "simpl-driver.hpp"
#include "simpl-lang.hpp"

Simpl_driver::Simpl_driver()
  : trace_scanning (false), trace_parsing (false)
{
}

Simpl_driver::~Simpl_driver ()
{
}

int Simpl_driver::parse(const std::string& f)
{
  filename = f;
  scan_begin();
  yy::Parser parser(*this);
  parser.set_debug_level(trace_parsing);
  int result = parser.parse();
  scan_end();
  return result;
}

void Simpl_driver::error(const yy::location& l, const std::string& m)
{
  std::cerr << filename << ": " << l << ": " << m << std::endl;
}

void Simpl_driver::error(const std::string& m)
{
  extern yy::location loc;
  std::cerr << filename << ": " << loc << ": " << m << std::endl;
}
