Yacc, lex and gcc must be installed.
Next in the repository with files the following commands:

yacc -d gram.y
lex lex.l
gcc gram.tab.c lex.yy.c
./a <name of file with python code>
