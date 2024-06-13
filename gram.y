
%code {
  #include <stdio.h>
  int yylex();
  void yyerror(const char *s);
  extern int yylineno;
}

%locations
%define api.push-pull push

%token IMPORT FROM AS
%token IF ELIF ELSE WHILE FOR
%token DEF CLASS
%token OPERATION SUM ARITH EQUALS DOT
%token TWOSTAR TWODIR SHIFT OPASSIGN
%token CONTROL RETURN
%token DEL PASS
%token REGION
%token YIELD TRY EXCEPT FINALLY RAISE ASSERT
%token WITH AND OR
%token NAME NUMBER STRING
%token ENTER
%token REAL

%%

main: | 
  ENTER | 
  ENTER block | 
  block
block: part | 
  part block 
part: 
  block_class set |
  block_func set |
  line | 
  FOR list_expressions OPERATION list_condition ':' set if_else | 
  IF condition ':' set if_elif if_else |
  block_try |
  block_try try_tail |
  WITH with_list ':' set |  
  WHILE condition ':' set if_else 
  
line: part_line ENTER | 
  part_line ';' ENTER | 
  part_line ';' line

part_line: block_expression | 
  DEL list_expressions | 
  PASS | 
  CONTROL | 
  RETURN | 
  RETURN list_condition | 
  expression_yield |
  RAISE | 
  RAISE condition | 
  RAISE condition FROM condition | 
  IMPORT block_name | 
  import_from  |
  REGION list_name|  
  ASSERT list_condition

block_class: CLASS NAME ':' |
  CLASS NAME '(' ')' ':' |
  CLASS NAME '(' list_arguments ')' ':'

block_func: DEF NAME '(' ')' ':' |
  DEF NAME '(' list_variables ')' ':'

block_expression: element_expression OPASSIGN expression_yield |
  element_expression OPASSIGN list_condition | 
  expression_list |
  expression_list EQUALS expression_yield |
  expression_list EQUALS block_expression

block_name: name_as |
  name_as ',' block_name |
  name_as ','
  
name_as: method |
  method AS NAME

set: line | 
  ENTER block 

element: NAME |
  NUMBER |
  strings | 
  REAL |
  brackets

strings: STRING |
  STRING strings

method: NAME |
  NAME DOT method

import_from: import_start IMPORT ARITH |
  import_start IMPORT block_name |
  import_start IMPORT '(' block_name ')'
import_start: FROM import_from_dot method | 
  FROM import_from_dot | 
  FROM method
import_from_dot: DOT |
  DOT import_from_dot 

if_elif: | 
  ELIF condition ':' set if_elif
if_else: | 
  ELSE ':' set

simple_except_rule: EXCEPT |
  EXCEPT condition |
  EXCEPT condition AS NAME 
except_rule: simple_except_rule ':' set | 
  simple_except_rule ':' set except_rule
block_try: TRY ':' set except_rule |
  TRY ':' set FINALLY ':' set
try_tail: ELSE ':' set|
  ELSE ':' set FINALLY ':' set|
  FINALLY ':' set

expression_double_star: TWOSTAR expression

condition: expression_or |
  expression_or IF expression_or ELSE condition 

expression_or: expression_and | 
  expression_and OR expression_or

expression_and: expression_not | 
  expression_not AND expression_and

expression_not: OPERATION expression_not | 
  expression compare

compare: | 
  OPERATION expression compare

expression: xor_expression | 
  xor_expression '|' expression

xor_expression: and_expression | 
  and_expression '^' xor_expression

and_expression: shift_expression | 
  shift_expression '&' and_expression

shift_expression: sum_expression | 
  sum_expression SHIFT shift_expression

sum_expression: arithmetic_expression | 
  arithmetic_expression SUM sum_expression

arithmetic_expression: unary_expression | 
  unary_expression ARITH arithmetic_expression

unary_expression: SUM unary_expression |
  pow_expression

pow_expression: element_expression |
  element_expression TWOSTAR unary_expression

element_expression: element element_expression_tails
element_expression_tails: |
  element_expression_tail element_expression_tails
element_expression_tail: '(' list_arguments ')'|
  '(' ')'|
  '[' sequence ']'|
  DOT NAME

expression_yield: YIELD |
  YIELD FROM condition |
  YIELD list_condition

block_comprehensions: comprehensions_for |
  comprehensions_if
comprehensions_for: FOR list_expressions OPERATION expression_or |
  FOR list_expressions OPERATION expression_or block_comprehensions
comprehensions_if: IF expression_or |
  IF expression_or block_comprehensions

list_arguments: argument |
  argument ',' |
  argument ',' list_arguments
argument: condition|
  condition comprehensions_for |
  condition EQUALS condition |
  TWOSTAR condition  |
  ARITH condition

 brackets: '(' expression_yield ')' |
  '(' testlist_comp ')' |
  '[' testlist_comp ']' |
  '{' couple_conditions '}' |
  '{' condition ':' condition comprehensions_for '}' |
  '{' expression_list '}' |
  '{' condition_star comprehensions_for '}' |
  '(' ')' |
  '[' ']' |
  '{' '}'

sequence: element_sequence |
  element_sequence ',' |
  element_sequence ',' sequence
sequence_condition: |
  condition
second_sequence_condition: |
  ':' sequence_condition
element_sequence: condition |
  sequence_condition ':' sequence_condition second_sequence_condition

list_variables: variable | 
  variable ',' |
  variable ',' list_variables
variable: NAME equality_variable |
  ARITH |
  TWOSTAR |
  ARITH NAME |
  TWOSTAR NAME
equality_variable: |
  EQUALS condition

list_name: NAME |
  NAME ',' list_name

list_condition: condition |
  condition ',' |
  condition ',' list_condition

list_expressions: expression_star | 
  expression_star ',' | 
  expression_star ',' list_expressions
expression_star: expression | 
  ARITH expression

expression_list: condition_star |
  condition_star ',' | 
  condition_star ',' expression_list
condition_star: condition |
  ARITH expression

testlist_comp: condition_star comprehensions_for |
  expression_list

couple_conditions: couple_condition |
  couple_condition ',' |
  couple_condition ',' couple_conditions

couple_condition: condition ':' condition |
  expression_double_star

element_with: condition |
  condition AS expression
with_list: element_with |
  element_with ',' with_list

%%

void yyerror(const char *s) {
  printf("Error [%d]: %s\n", yylloc.last_line, s);
}
