%{
#include <stdio.h>
#include <stdlib.h>
#include <bits/stdc++.h>
using namespace std;
void yyerror(char* s);
int yylex(void);

ofstream fout;	//fout if file object of output file 

void addToStack();	//function to add yytext string to stack 
void codegen_exp();	//function to genrate code for expression grammar 
void check();		//function to check if variable used in assignment is declared or not 
void statement_declare_start();	// function to check if variable declared is already declared or not 
void setType();			//to set Type of variable declared as int,uint or bool 
void codegen_assign();	//function to genrate code for assignment statement 
void codegen_operator_assign();	//function to genrate code for operator assignment statement 
void if_start_label();	// to declare label for false condition of if 
void if_end_label();	// to declare label for ending part of if-else block 
void if_middle_label();	// to declare label for else part of if-else block 
void while_start_label(); // to declare label for start of while loop 
void while_body_label(); //to declare label for goto start label of while loop 
void while_end_label();	// to declare label for ending part of while 
void switch_start_label(); // to declare label for start of switch statement 
void switch_case_label(); 
void switch_end_label();
void switch_break_label();	// to declare label for break statment of switch 
void switch_nobreak_label();
void switch_default_label();
void checkAndSplit();	//function to check and split operator assignment statements as conflict might arise with assignment statements 
void codegen_exp_not(); //function to genrate negate expression 

stack<string> s;	//stack for storing E.code data 
stack<int> label;	//stack for label numbers 
stack<int> switch_stack;
int label_id=0;		//label id values 

struct table_entry	//symbol table entry 
{
	string type;	//int,bool or uint 
	int value;		//value of variable 
};

map<string,table_entry> symbol_table; 	//symbol table data structure 
int temp_id=0;	// temporary variable id values 
string global_type;	// used while declaring variables 

%}

%token INT VOID UINT BOOL 
%token IF ELSE WHILE SWITCH BREAK CASE DEFAULT  
%token NUM ID 
%token PLUS MINUS MULTIPLY DIVIDE POWER
%token ASGN PLUS_ASGN MINUS_ASGN MULTIPLY_ASGN DIV_ASGN
%token LOR LAND BOR BXOR BAND EQ NE LE GE LT GT 
%right ASGN 
%left LOR
%left LAND
%left BOR
%left BXOR
%left BAND
%left EQ NE 
%left LE GE LT GT
%left PLUS MINUS 
%left MULTIPLY DIVIDE
%right POWER
%left NOT

%nonassoc IFX IFX1
%nonassoc ELSE

%%

PROGRAM				:INT ID '(' ')' STATEMENTS		// int main() {..}
					;

STATEMENTS			:'{' MULTIPLE_STATEMENTS '}'	
					|
					;

MULTIPLE_STATEMENTS	:ATOMIC_STATEMENT MULTIPLE_STATEMENTS
					|
					;

ATOMIC_STATEMENT	:DECLARE_STATEMENT
					|ASSIGN_STATEMENT
					|OP_ASGN
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
				| EXP PLUS{ addToStack();} EXP {codegen_exp();}
				| EXP MINUS{ addToStack();} EXP {codegen_exp();}
				| EXP MULTIPLY{ addToStack();} EXP {codegen_exp();}
				| EXP DIVIDE{ addToStack();} EXP {codegen_exp();}
                | EXP LOR { addToStack();} EXP {codegen_exp();}
				| EXP LAND { addToStack();} EXP {codegen_exp();}
				| EXP BOR { addToStack();}EXP {codegen_exp();}
				| EXP BXOR { addToStack();} EXP {codegen_exp();}
				| EXP BAND { addToStack();}EXP {codegen_exp();}
				| EXP POWER { addToStack();} EXP {codegen_exp();}
				| NOT { addToStack(); } EXP { codegen_exp_not(); }
				| '(' EXP ')'
				| ID { check();addToStack();}
				| NUM { addToStack();}
				;

TYPE 			: INT
				| UINT
				| BOOL
				;

OP_ASGN			: PLUS_ASGN  { checkAndSplit(); } EXP { codegen_operator_assign(); } ';' 
				| MINUS_ASGN { checkAndSplit(); } EXP { codegen_operator_assign(); } ';' 
				| MULTIPLY_ASGN { checkAndSplit(); } EXP { codegen_operator_assign(); } ';' 
				| DIV_ASGN { checkAndSplit(); } EXP { codegen_operator_assign(); } ';' 
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
void addToStack()		//Adding contents of yytext to stack 
{
	string temp(yytext);
	cout<<temp<<" stack\n";
	s.push(temp);
}
void codegen_exp_not()	//Three Address Code for not expression 
{
	temp_id++;
	char temp[10];
	sprintf(temp,"_t%d",temp_id);//Genration of Temp. Variable 
	string lval(temp);

	string id=s.top();s.pop();
	string op=s.top();s.pop();
	fout<<lval<<" = "<<op<<id<<endl; //lval=rval type three address code 
	s.push(lval);
}
void codegen_exp()	//Three Address Code for expression statements 
{
	temp_id++;
	char temp[10];
	sprintf(temp,"_t%d",temp_id);//Genration of Temp. Variable 
	string lval(temp);

	string id2=s.top();s.pop();
	string op=s.top();s.pop();
	string id1=s.top();s.pop();
	fout<<lval<<" = "<<id1<<" "<<op<<" "<<id2<<endl; //lval=id1 op id2 type of three address code 
	s.push(lval);
}
void codegen_assign()	//Three Address Code for assignment statements 
{
	string id2=s.top();s.pop();
	string op=s.top();s.pop();
	string id1=s.top();s.pop();
	fout<<id1<<" "<<op<<" "<<id2<<endl; //lval=rval type three address code 
}
void checkAndSplit()	//yytext contains id+=,id-= type of statements used for avoiding conflict with id=exp statements 
{
	string temp(yytext);
	string id=temp.substr(0,temp.length()-2);
	temp=temp.substr(temp.length()-2);
	if(symbol_table.find(id)==symbol_table.end())
	{
		cout<<id<<" Variable not defined\n";
		exit(0);
	}
	s.push(id);
	s.push(temp);
}
void codegen_operator_assign()	//Three Address Code for operator assignment statements 
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

void if_start_label()		//Start label of false condition of if and store in label stack 
{
	label_id++;
	label.push(label_id);
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<"if not "<<s.top()<<" goto "<<temp<<endl;
}
void if_middle_label()		//After block of if statements -> goto new label ( added to stack )
{							// and top label represent current set of statements 
	label_id++;
	int prev=label.top();label.pop();
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<"goto "<<temp<<endl;
	label.push(label_id);
	fout<<"$L"<<prev<<":"<<endl;
}
void if_end_label()			//Top label represents end of block  
{
	int prev=label.top();label.pop();
	char temp[10];
	sprintf(temp,"$L%d",prev);
	fout<<"$L"<<prev<<":"<<endl;
	s.pop();
}	 

void while_start_label()	//Start label of while loop 
{
	label_id++;
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<temp<<":"<<endl;
	label.push(label_id);
}

void while_body_label()		// if condition is false goto label of next statements after while loop 
{
	label_id++;
	char temp[10];
	sprintf(temp,"$L%d",label_id);
	fout<<"if not "<<s.top()<<" goto "<<temp<<endl;
	label.push(label_id);
	s.pop();
}
void while_end_label()		// goto represents start label again.
{
	int prev=label.top();label.pop();
	int prev2=label.top();label.pop();
	fout<<"goto $L"<<prev2<<":"<<endl;
	fout<<"$L"<<prev<<":"<<endl;
}
void switch_start_label()	//2 labels genrated one for first case and end of switch statement 
{
	label_id++;
	label.push(label_id);
	label_id++;
	label.push(label_id);
	switch_stack.push(1);
}
void switch_case_label()	// z represent condition for break
{
	int x,y,z;
	z=switch_stack.top();switch_stack.pop();
	if(z==1)
	{
		x=label.top();	//break present 
		label.pop();
	}
	else if(z==2)
	{
		y=label.top();
		label.pop();	//No break present 
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
void switch_default_label()	//Default statement label 
{
	fout<<"$L"<<label.top()<<":\n";
	label.pop();
	label_id++;
	label.push(label_id);
}

void switch_break_label()	// Break label's goto will be end of switch statement label 
{
	switch_stack.push(1);
	int prev=label.top();label.pop();
	int prev2=label.top();
	label.push(prev);
	fout<<"goto $L"<<prev2<<":\n";
}
void switch_nobreak_label()	//No break label's goto will be label of next case statements 
{
	switch_stack.push(2);
	label_id++;
	label.push(label_id);
	fout<<"goto $L"<<label_id<<":\n";
}
void switch_end_label()		//End of switch statement,two labels because one for last case statement and one for end of switch 
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
	yyin = fopen(argv[1], "r");		//Input test file 
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
