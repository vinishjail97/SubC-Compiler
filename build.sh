lex subc.l
yacc -d subc.y
g++ y.tab.c -ll -ly
./a.out test
