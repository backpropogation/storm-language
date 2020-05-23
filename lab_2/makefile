CXX = clang++
CXXFLAGS = -g -Wall -std=c++11 -Wno-deprecated-register -Wno-unused-private-field -O0
LEX = flex
LFLAGS = --noline
YACC = bison --report=all -d -l

EXE = parser
# Things that get included in our Yacc file
INCLUDED_FILES = \
	ast.hpp \
	subexpression.hpp \
	symtable.hpp \
        simpl-driver.hpp

# The various .o files that are needed for executables.
OBJECT_FILES = simpl-lang.o ast.o simpl-lexer.o simpl-driver.o symtable.o

.PHONY: default
default: parser

.PHONY: parser
parser: $(OBJECT_FILES) parser.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

simpl-lang.o: simpl-lang.cpp $(INCLUDED_FILES)

.PHONY: simpl-lang.cpp
simpl-lang.cpp: simpl-language.y
	$(YACC) $(YFLAGS) $^ -o simpl-lang.cpp

simpl-lexer.cpp: lexer.l
	$(LEX) $(LFLAGS) --outfile=simpl-lexer.cpp $^

.PHONY: clean-all
clean-all:
	make clean
	$(RM) parser

.PHONY: clean
clean:
	-$(RM) *.o
	-$(RM) *.hh
	-$(RM) simpl-lang.*
	-$(RM) simpl-lexer.*
