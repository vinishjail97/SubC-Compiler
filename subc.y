%{
#include <stdio.h>
#include <stdlib.h>
#include <bits/stdc++.h>
using namespace std;
void yyerror(char* s);
int yylex(void);

ofstream fout;

void addToStack();
void codegen_exp();
void check();
void statement_declare_start();
void setType();
void codegen_assign();
void codegen_operator_assign();
void if_start_label();
void if_end_label();
void if_middle_label();
void while_start_label();
void while_body_label();
void while_end_label();
void switch_start_label();
void switch_case_label();
void switch_end_label();
void switch_break_label();
void switch_nobreak_label();
void switch_default_label();

stack<string> s;
stack<int> label;
stack<int> switch_stack;
int label_id=0;

struct table_entry
{
	string type;
	int value;
};

map<string,table_entry> symbol_table;
int temp_id=0;
string global_type;

%}

%token INT VOID UINT BOOL 
%token IF ELSE WHILE SWITCH BREAK CASE DEFAULT  
%token NUM ID 
%right ASGN PLUS_ASGN MINUS_ASGN MULTIPLY_ASGN DIV_ASGN
%left LOR
%left LAND
%left BOR
%left BXOR
%left BAND
%left EQ NE 
%left LE GE LT GT
%left '+' '-' 
%left '*' '/' '@'
%left '~'

%nonassoc IFX IFX1
%nonassoc ELSE

%%

PROGRAM				:INT ID '(' ')' STATEMENTS
					;

STATEMENTS			:'{' MULTIPLE_STATEMENTS '}'
					|
					;

MULTIPLE_STATEMENTS	:ATOMIC_STATEMENT MULTIPLE_STATEMENTS
					|
					;

ATOMIC_STATEMENT	:DECLARE_STATEMENT
					|ASSIGN_STATEMENT
					|IF_STATEMENT
					|WHILE_STATEMENT
					|SWITCH_STATEMENT
					|';'
					;

IF_STATEMENT		: IF '(' EXP ')' { if_start_label(); } STATEMENTS ELSESTMT
					;

ELSESTMT			: ELSE { if_middle_label(); } STATEMENTS { if_end_label(); } 
					| { if_end_label(); }
					;

WHILE_STATEMENT		: { while_start_label(); } WHILE '(' EXP ')' { while_body_label(); } WHILEBODY	
					;
WHILEBODY			: STATEMENTS { while_end_label(); }
					;


SWITCH_STATEMENT	: SWITCH '(' EXP ')' { switch_start_label(); } '{' SWITCHBODY '}'
					;

SWITCHBODY		: CASES { switch_end_label(); }    
				| CASES DEFAULTSTMT { switch_end_label(); }
				;

CASES 			: CASE NUM { switch_case_label(); } ':' SWITCHEXP BREAKSTMT
				| 
				;

BREAKSTMT		: BREAK { switch_break_label(); } ';' CASES
				|{ switch_nobreak_label(); } CASES 
				;

DEFAULTSTMT 	: DEFAULT { switch_default_label(); } ':' SWITCHEXP DE  
				;

DE 				: BREAK { switch_break_label(); }';'
				|
				;

SWITCHEXP 		: STATEMENTS
				| ATOMIC_STATEMENT
				;


EXP 			: EXP LT{ addToStack();} EXP {codegen_exp();}
				| EXP LE{ addToStack();} EXP {codegen_exp();}
				| EXP GT{ addToStack();} EXP {codegen_exp();}
				| EXP GE{ addToStack();} EXP {codegen_exp();}
				| EXP NE{ addToStack();} EXP {codegen_exp();}
				| EXP EQ{ addToStack();} EXP {codegen_exp();}
				| EXP '+'{ addToStack();} EXP {codegen_exp();}
				| EXP '-'{ addToStack();} EXP {codegen_exp();}
				| EXP '*'{ addToStack();} EXP {codegen_exp();}
				| EXP '/'{ addToStack();} EXP {codegen_exp();}
                | EXP LOR { addToStack();} EXP {codegen_exp();}
				| EXP LAND { addToStack();} EXP {codegen_exp();}
				| EXP BOR { addToStack();}EXP {codegen_exp();}
				| EXP BXOR { addToStack();} EXP {codegen_exp();}
				| EXP BAND { addToStack();}EXP {codegen_exp();}
				| '(' EXP ')'
				| ID { check();addToStack();}
				| NUM { addToStack();}
				;

TYPE 			: INT
				| UINT
				| BOOL
				;

OP_ASGN			: PLUS_ASGN
				| MINUS_ASGN
				| MULTIPLY_ASGN
				| DIV_ASGN
				;

DECLARE_STATEMENT	: TYPE { setType(); } ID { statement_declare_start(); } IDS
					;

IDS					: ';'
					| ',' ID { statement_declare_start(); } IDS
					;

ASSIGN_STATEMENT	: ID { check();addToStack(); } ASGN { addToStack(); } EXP { codegen_assign(); } ';'
					;

%%



#include <ctype.h>
#include"lex.yy.c"

void yyerror(char* s){
	printf("Error = %s\n", s);
	return;
}
void addToStack()
{
	string temp(yytext);
	s.push(temp);
}
void codegen_exp()
{
	temp_id++;
	char temp[10];
	sprintf(temp,"_t%d",temp_id);
	string lval(temp);

	string id2=s.top();s.pop();
	string op=s.top();s.pop();
	string id1=s.top();s.pop();
	fout<<lval<<" = "<<id1<<" "<<op<<" "<<id2<<endl;
	s.push(lval);
}
void codegen_assign()
{
	string id2=s.top();s.pop();
	string op=s.top();s.pop();
	string id1=s.top();s.pop();
	fout<<id1<<" "<<op<<" "<<id2<<endl;
}
void codegen_operator_assign()
{
	string id2=s.top();s.pop();
	string op=s.top();s.pop();
	string id1=s.top();s.pop();
	
	if(op=="+=")
		op="+";
	else if(op=="-=")
		op="-";
	else if(op=="*=")
		op="*";
	else
		op="/";
	
	fout<<id1<<" = "<<id1<<" "<<op<<" "<<id2<<endl;
}	
void check()
{
	string id(yytext);
	if(symbol_table.find(id)==symbol_table.end())
	{
		cout<<id<<" Variable not defined\n";
		exit(0);
	}
}
void setType()
{
	global_type=string(yytext);
	
}
void statement_declare_start()
{
	string id(yytext);
	if(symbol_table.find(id)!=symbol_table.end())
	{
		cout<<id<<" Variable re defined\n";
		exit(0);
	}
	symbol_table[id].type=global_type;
}

void if_start_label()
{
	label_id++;
	label.push(label_id);
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<"if not "<<s.top()<<" goto "<<temp<<endl;
}
void if_middle_label()
{
	label_id++;
	int prev=label.top();label.pop();
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<"goto "<<temp<<endl;
	label.push(label_id);
	fout<<"$L"<<prev<<":"<<endl;
}
void if_end_label()
{
	int prev=label.top();label.pop();
	char temp[10];
	sprintf(temp,"$L%d",prev);
	fout<<"$L"<<prev<<":"<<endl;
	s.pop();
}	 

void while_start_label()
{
	label_id++;
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<temp<<":"<<endl;
	label.push(label_id);
}

void while_body_label()
{
	label_id++;
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<"if not "<<s.top()<<" goto "<<temp<<endl;
	label.push(label_id);
	s.pop();
}
void while_end_label()
{
	int prev=label.top();label.pop();
	int prev2=label.top();label.pop();
	fout<<"goto $L"<<prev2<<":"<<endl;
	fout<<"$L"<<prev<<":"<<endl;
}
void switch_start_label()
{
	label_id++;
	label.push(label_id);
	label_id++;
	label.push(label_id);
	switch_stack.push(1);
}
void switch_case_label()
{
	int x,y,z;
	z=switch_stack.top();switch_stack.pop();
	if(z==1)
	{
		x=label.top();
		label.pop();
	}
	else if(z==2)
	{
		y=label.top();
		label.pop();
		x=label.top();
		label.pop();
	}
	
	fout<<"$L"<<x<<":\n";
	label_id++;
	label.push(label_id);
	fout<<"if "<<s.top()<<" not "<<yytext<<" goto "<<"$L"<<label_id<<endl;
	if(z==2)
	{
		fout<<"$L"<<y<<":\n";
	}
}
void switch_default_label()
{
	fout<<"$L"<<label.top()<<":\n";
	label.pop();
	label_id++;
	label.push(label_id);
}

void switch_break_label()
{
	switch_stack.push(1);
	int prev=label.top();label.pop();
	int prev2=label.top();
	label.push(prev);
	fout<<"goto $L"<<prev2<<":\n";
}
void switch_nobreak_label()
{
	switch_stack.push(2);
	label_id++;
	label.push(label_id);
	fout<<"goto $L"<<label_id<<":\n";
}
void switch_end_label()
{
	fout<<"$L"<<label.top()<<":\n";
	label.pop();
	fout<<"$L"<<label.top()<<":\n";
	label.pop();
	s.pop();
	switch_stack.pop();
}
int main(int argc, char *argv[])
{
	yyin = fopen(argv[1], "r");
	fout.open("output.txt");
	
   if(!yyparse())
		printf("\nParsing complete\n");
	else
	{
		printf("\nParsing failed\n");
		exit(0);
	}
	
	fclose(yyin);
	fout.close();
    return 0;
}



				


