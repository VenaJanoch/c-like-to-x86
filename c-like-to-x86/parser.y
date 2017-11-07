%{

#include <stdio.h>
#include <stdlib.h>

#include "Compiler.h"

void yyerror(const char* s);

extern int yylex();
extern int yyparse();
extern FILE* yyin;
extern int yylineno;
extern char* yytext;

Compiler compiler;

%}

%locations
%define parse.error verbose

%token CONST STATIC VOID BOOL UINT8 UINT16 UINT32 STRING CONSTANT IDENTIFIER
%token IF ELSE RETURN DO WHILE FOR
%token EQUAL NOT_EQUAL GREATER_OR_EQUAL LESS_OR_EQUAL
%token SHIFT_LEFT SHIFT_RIGHT
%token LOG_AND LOG_OR

%right '='
%left EQUAL NOT_EQUAL LESS_OR_EQUAL GREATER_OR_EQUAL '<' '>'
%left SHIFT_LEFT SHIFT_RIGHT
%left LOG_AND LOG_OR
%left '+' '-' '*' '/' '%'

%union
{
    char* string;
    SymbolType type;
	ReturnSymbolType return_type;
}

%type <string> id IDENTIFIER
%type <type> declaration_type declaration static_declaration
%type <return_type> return_type

%start program_head

%%

program_head
    : program
		{
		}
    ;

program
    : jump_marker function
        {
            Log("P: Processing single function");

        }
    | program function
        {
            Log("P: Processing function in function list");

        }
    ;


// Parts of function declaration
function
    : return_type id '(' parameter_list ')' ';'
        {
        }
    | return_type id '(' parameter_list ')' function_body
        {
        }
	| static_declaration_list
		{
		}
    ;

function_body
    : '{' statement_list  '}'
        {
            Log("P: Found function body");
        }
    ;

parameter_list
    : declaration_type id
        {
            Log("P: Found parameter");
        }
    | parameter_list ',' declaration_type id
        {

            Log("P: Found parameter list (end)");
        }
    | VOID
        {
            Log("P: Found VOID parameter");
        }
    |
        {
            Log("P: Found no parameter");
        }
    ;

// Types that can be used for variable declarations and function parameters
declaration_type
	: BOOL
        {
            $$ = SymbolType::Bool;

			Log("P: Found BOOL declaration_type");
        }
	| UINT8
        {
            $$ = SymbolType::Uint8;

			Log("P: Found UINT8 declaration_type");
        }
	| UINT16
        {
            $$ = SymbolType::Uint16;

			Log("P: Found UINT16 declaration_type");
        }
	| UINT32
        {
            $$ = SymbolType::Uint32;

			Log("P: Found UINT32 declaration_type");
        }
	| STRING
        {
            $$ = SymbolType::String;

			Log("P: Found STRING declaration_type");
        }
    ;

// Types that can be used for function return value
return_type
	: BOOL
        {
            $$ = ReturnSymbolType::Bool;

            Log("P: Found BOOL return_type");
        }
	| UINT8
        {
            $$ = ReturnSymbolType::Uint8;

            Log("P: Found UINT8 return_type");
        }
	| UINT16
        {
            $$ = ReturnSymbolType::Uint16;

            Log("P: Found UINT16 return_type");
        }
	| UINT32
        {
            $$ = ReturnSymbolType::Uint32;

            Log("P: Found UINT32 return_type");
        }
	| STRING
        {
            $$ = ReturnSymbolType::String;

            Log("P: Found STRING return_type");
        }
	| VOID
        {
            $$ = ReturnSymbolType::Void;

            Log("P: Found VOID return_type");
        }
    ;

	// Statements
statement_list
    : statement
        {
			Log("P: Processing single statement in list statement list");
        }
    | statement_list marker statement
        {
			Log("P: Processing statement list");
        }
    ;

statement
    : matched_statement
        {
			Log("P: Processing matched statement");
        }
    | unmatched_statement
        {
			Log("P: Processing unmatched statement");
        }
	| declaration_list
		{
			Log("P: Processing declaration list");
		}
	| goto_label
		{
			Log("P: Processing goto label");
		}
    ;

matched_statement
    : IF '(' assignment ')' matched_statement ELSE matched_statement
        {
			Log("P: Processing matched if..else");

			CheckIsIntOrBool($3, "Only integer and bool types are allowed in \"if\" statement", @3);
        }
    | assignment_with_declaration ';'
        {
			Log("P: Processing matched assignment");
		}
    | RETURN ';'
        {
			Log("P: Processing void return");
        }
    | RETURN assignment ';'
        {
			Log("P: Processing value return");
        }
    | WHILE '(' assignment ')' matched_statement
        {
			Log("P: Processing matched while");

			CheckIsIntOrBool($4, "Only integer and bool types are allowed in \"while\" statement", @4);
        }
    | DO statement WHILE '(' assignment ')' ';'
        {
			Log("P: Processing matched do..while");

			CheckIsIntOrBool($7, "Only integer and bool types are allowed in \"while\" statement", @7);
        }
    | FOR '(' assignment_with_declaration ';' assignment ';' assignment ')' matched_statement
        {
            Log("P: Processing matched for");

            CheckIsInt($3, "Integer assignment is required in the first part of \"for\" statement", @3);
			CheckIsBool($6, "Bool expression is required in the middle part of \"for\" statement", @6);
			CheckIsInt($9, "Integer assignment is required in the last part of \"for\" statement", @9);
        }
	| GOTO id ';'
		{
			Log("P: Processing goto command");
		}
    | '{' statement_list '}'
        {
			Log("P: Processing statement block");
        }
    | '{' '}'
        {	    
			Log("P: Processing empty block");
        }
    ;

unmatched_statement
    : IF '(' assignment ')' statement
        {
			Log("P: Processing unmatched if");

			CheckIsIntOrBool($3, "Only integer and bool types are allowed in \"if\" statement", @3);
        }
    | WHILE '(' assignment ')' unmatched_statement
        {
			Log("P: Processing unmatched while");

			CheckIsIntOrBool($4, "Only integer and bool types are allowed in \"while\" statement", @4);
        }
    | FOR '(' assignment_with_declaration ';' assignment ';' assignment ')' unmatched_statement
        {
            Log("P: Processing unmatched for");

			CheckIsInt($3, "Integer assignment is required in the first part of \"for\" statement", @3);
			CheckIsBool($6, "Bool expression is required in the middle part of \"for\" statement", @6);
			CheckIsInt($9, "Integer assignment is required in the last part of \"for\" statement", @9);
        }

    | IF '(' assignment ')' matched_statement ELSE unmatched_statement
        {
			Log("P: Processing unmatched if else");

			CheckIsIntOrBool($3, "Only integer and bool types are allowed in \"if\" statement", @3);
        }
    ;
	
// Variable declaration, without assignment
declaration_list
    : declaration ';'
        {
            Log("P: Found declaration");
        }
    ;

declaration
    : declaration_type id
        {
            Log("P: Found variable declaration");
        }
    | declaration ',' id
        {
			CheckTypeIsValid($1, @1);

            Log("P: Found multiple declarations");
        }
    ;

// Static variable declaration, without assignment
static_declaration_list
    : static_declaration ';'
        {
            Log("P: Found static declaration");
        }
    ;

static_declaration
    : STATIC declaration_type id
        {
            Log("P: Found static variable declaration");
        }
    | STATIC static_declaration ',' id
        {
			CheckTypeIsValid($2, @2);

            Log("P: Found multiple static declarations");
        }
    ;

// Variable assignment, without type declaration
assignment
    : expression
        {
            Log("P: Found expression as assignment " << $1.value);
        }
    | id '=' expression
		{
			Log("P: Found assignment");
        }
    ;

// Variable assignment, could be with or without type declaration
assignment_with_declaration
    : assignment
        {
            Log("P: Found assignment without declaration \"" << $1.value << "\"");
        }
	| CONST declaration_type id '=' expression
		{
			Log("P: Found const. variable declaration with assignment \"" << $3 << "\"");
        }
	| declaration_type id '=' expression
		{
			Log("P: Found variable declaration with assignment \"" << $2 << "\"");
        }
    ;

expression
    : INC_OP expression
        {
			Log("P: Processing increment");

			CheckIsInt($2, "Specified type is not allowed in arithmetic operations", @1);
        }
    | DEC_OP expression
        {
			Log("P: Processing decrement");

			CheckIsInt($2, "Specified type is not allowed in arithmetic operations", @1);
        }
    | expression LOG_OR expression
        {

	    }
    | expression LOG_AND expression
		{

		}
    | expression NOT_EQUAL expression
        {
			Log("P: Processing logical not equal");

			CheckIsIntOrBool($1, "Only integer and bool types are allowed in comparsions", @1);
			CheckIsIntOrBool($3, "Only integer and bool types are allowed in comparsions", @3);
        }
    | expression EQUAL expression
        {
			Log("P: Processing logical equal");

			CheckIsIntOrBool($1, "Only integer and bool types are allowed in comparsions", @1);
			CheckIsIntOrBool($3, "Only integer and bool types are allowed in comparsions", @3);
        }
    | expression GREATER_OR_EQUAL expression
        {
			Log("P: Processing logical greater or equal");

			CheckIsInt($1, "Only integer types are allowed in comparsions", @1);
			CheckIsInt($3, "Only integer types are allowed in comparsions", @3);
        }
    | expression LESS_OR_EQUAL expression
        {
			Log("P: Processing logical smaller or equal");

			CheckIsInt($1, "Only integer types are allowed in comparsions", @1);
			CheckIsInt($3, "Only integer types are allowed in comparsions", @3);
        }
    | expression '>' expression
        {
			Log("P: Processing logical bigger");

			CheckIsInt($1, "Only integer types are allowed in comparsions", @1);
			CheckIsInt($3, "Only integer types are allowed in comparsions", @3);
        }
    | expression '<' expression
        {
			Log("P: Processing logical smaller");

			CheckIsInt($1, "Only integer types are allowed in comparsions", @1);
			CheckIsInt($3, "Only integer types are allowed in comparsions", @3);
        }
    | expression SHIFT_LEFT expression
        {
			Log("P: Processing left shift");

			CheckIsInt($1, "Only integer types are allowed in shift operations", @1);
			CheckIsInt($3, "Only integer types are allowed in shift operations", @3);
        }
	| expression SHIFT_RIGHT expression
        {
			Log("P: Processing left shift");

			CheckIsInt($1, "Only integer types are allowed in shift operations", @1);
			CheckIsInt($3, "Only integer types are allowed in shift operations", @3);
        }
    | expression '+' expression
        {
			Log("P: Processing addition");
        }
    | expression '-' expression
        {
			Log("P: Processing substraction");
        }
    | expression '*' expression
        {
			Log("P: Processing multiplication");
        }
    | expression '/' expression
        {
			Log("P: Processing division");
        }
    | expression '%' expression
        {
			Log("P: Processing remainder");
        }
    | '!' expression
        {
			Log("P: Processing logical not");
		}
    | U_PLUS expression
        {
			CheckIsInt($2, "Unary operator is not allowed in this context", @1);
        }
    | U_MINUS expression
        {
			CheckIsInt($2, "Unary operator is not allowed in this context", @1);
       }
    | CONSTANT
        {
			Log("P: Processing constant");
        }
    | '(' expression ')'
        {
            Log("P: Processing expression in parentheses");
        }
    | id '(' call_parameter_list ')'
        {
			Log("P: Processing function call with parameters");
        }
    | id '('  ')'
        {
			Log("P: Processing function call");
        }
    | id
        {
			Log("P: Processing identifier");
        }
    ;

call_parameter_list
    : expression
        {
			Log("P: Processing call parameter list");

			CheckTypeIsValid($1.type, @1);
        }
    | call_parameter_list ',' expression
        {
			Log("P: Processing call parameter list");

			CheckTypeIsValid($3.type, @3);
        }
    ;

// Goto
// ToDo: Add beginning-of-line only marker?
goto_label
	: id ':'
		{
			Log("P: Found goto label \"" << $1 << "\"");
		}
	;

// Misc.
id
    : IDENTIFIER
        {
			Log("P: Found identifier \"" << $1 << "\"");

			$$ = _strdup(yytext);
        }
    ;

%%

int __cdecl wmain(int argc, wchar_t *argv[], wchar_t *envp[])
{
	return compiler.OnRun(argc, argv);
}

void yyerror(const char* s)
{
	if (memcmp(s, "syntax error", 12) == 0) {
		if (memcmp(s + 12, ", ", 2) == 0) {
			throw CompilerException(CompilerExceptionSource::Syntax,
				s + 14, yylloc.first_line, yylloc.first_column);
		}

		throw CompilerException(CompilerExceptionSource::Syntax,
			s + 12, yylloc.first_line, yylloc.first_column);
	}

	throw CompilerException(CompilerExceptionSource::Syntax,
		s, yylloc.first_line, yylloc.first_column);
}
