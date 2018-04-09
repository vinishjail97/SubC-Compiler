alpha [a-zA-Z]
digit [0-9]

%%
[ \t]		;
[ \n]   { yylineno = yylineno + 1;}
"int"	return INT;
"bool"	return BOOL;
"unsigned int"	return UINT;
"case"	return CASE;
"break"	return BREAK;
"void" return VOID;
"while"	return WHILE;
"switch"	return SWITCH;
"default" return DEFAULT;
"if"	return IF;
"else"	return ELSE;
^"#include ".+ ;
{digit}+       return NUM;
{alpha}({alpha}|{digit})*  return ID; 
"="     { printf("%s\n",yytext); return ASGN; } 
{alpha}({alpha}|{digit})*"+="   return PLUS_ASGN; 
{alpha}({alpha}|{digit})*"-="	return MINUS_ASGN;
{alpha}({alpha}|{digit})*"*="	return MULTIPLY_ASGN;
{alpha}({alpha}|{digit})*"/="	return DIV_ASGN;
"+"		return PLUS;
"-"		return MINUS;
"*"		return MULTIPLY;
"/"		return DIVIDE;
"<="    return LE;
">="    return GE;
"=="    return EQ;
"!="    return NE;
">"	return GT;
"<"	return LT;
"@"	return POWER;
"||" 	return LOR;
"&&"  	return LAND;
"|" 	return BOR;
"&"	return BAND;
"^"	return BXOR;
"~"	return NOT;
\/\/.* ;
\/\*(.*\n)*.*\*\/ ;
.       return yytext[0];
%%

