%{
  #include <stdio.h>
  #include <unistd.h>
  #include "gram.tab.h" 


  yypstate *position = NULL;
  int implicit_brackets = 0;
  static char *buffer = 0;
  static int buffer_size = 0;
  extern int yychar;
  int yylex();
  void yyerror(const char *s);
  int my_input(char *buf);
  static int token_push(int token);
  static void update_line ();
  static struct{
    int prev_line;
    int now_line;
  }info = {0};
  
  
  #define YY_INPUT(buf, result, maxsize) result = my_input(buf);
  #define YY_USER_ACTION { update_line(); }   

%}

%option noyywrap

NAME ([_a-zA-Z][_a-zA-Z0-9]*)

STRING1 ([a-zA-Z]?['][^']*['])
STRING2 ([a-zA-Z]?["][^"]*["])
STRING ({STRING1}|{STRING2})

NUMBER1 ([0-9]+)
NUMBER2 ([0-9]*[.][0-9]+)
NUMBER3 ([0-9]+[.][0-9]*)
NUMBER4 ([0-9]*[.][0-9]+[e][+-][0-9]+)
NUMBER5 ([0-9]+[.][0-9]*[e][+-][0-9]+)
NUMBER ({NUMBER1}|{NUMBER2}|{NUMBER3}|{NUMBER4}|{NUMBER5})

%%

import {return IMPORT;}
from {return FROM;}
as {return AS;}

if {return IF;}
elif {return ELIF;}
else {return ELSE;}
while {return WHILE;}
for {return FOR;}

def {return DEF;}
class {return CLASS;}

"+" {return SUM;}
"-" {return SUM;}
"*" {return ARITH;}
"/" {return ARITH;}
"%" {return ARITH;}
"@" {return ARITH;}
"//" {return ARITH;}
"=" {return EQUALS;}
"." {return DOT;}



"==" {return OPERATION;}
"<=" {return OPERATION;}
">=" {return OPERATION;}
"<" {return OPERATION;}
">" {return OPERATION;}
"!=" {return OPERATION;}
"**" {return TWOSTAR;}
"<<" {return SHIFT;}
">>" {return SHIFT;}
"~" {return SUM;}

"+=" {return OPASSIGN;}
"-=" {return OPASSIGN;}
"*=" {return OPASSIGN;}
"@=" {return OPASSIGN;}
">>=" {return OPASSIGN;}
"<<=" {return OPASSIGN;}
"&=" {return OPASSIGN;}
"|=" {return OPASSIGN;}
"//=" {return OPASSIGN;}
"/=" {return OPASSIGN;}
"%=" {return OPASSIGN;}
"**=" {return OPASSIGN;}
"\^=" {return OPASSIGN;}

break {return CONTROL;}
continue {return CONTROL;}
return {return RETURN;}

del {return DEL;}
pass {return PASS;}
true {return REAL;}
false {return REAL;}
none {return REAL;}

global {return REGION;}
nonlocal {return REGION;}

yield {return YIELD;}
try {return TRY;}
except {return EXCEPT;}
finally {return FINALLY;}
raise {return RAISE;}
assert {return ASSERT;}

with {return WITH;}
not {return OPERATION;}
in {return OPERATION;}
is {return OPERATION;}

and {return AND;}
or {return OR;}

{NAME} {return NAME;}
{NUMBER} {return NUMBER;}
{STRING} {return STRING;}

[\r] {}
\n*([ \t]*#.*\n)*[ \t]*#.* {}

\[|\(|\{ {
    implicit_brackets++;
    return yytext[0];
}
\]|\)|\} {
    implicit_brackets--;
    return yytext[0];
}
\n+ {
    if (implicit_brackets) {YY_BREAK;}
    return ENTER;
}

[ \t]+ {}

. {return yytext[0];}

<<EOF>> {
    token_push(ENTER);
    return YY_NULL;
}

%%

int my_input(char *buf) {
  static int i = 0;
  if (i < buffer_size) {
    buf[0] = buffer[i];
    i++;
    return 1;
  } 
  return YY_NULL;
}

static int token_push(int token) {
    static int last_line = 0;
    if (token == ENTER && last_line) {
      return YYPUSH_MORE;
    }
    last_line = (token == ENTER) ? 1 : 0;
    yychar = token;
    return yypush_parse(position);
  }

static void update_line () {
    static int current_line = 1;
    yylloc.first_line   = current_line;
    info.prev_line = info.now_line;
    char *s = yytext;
    while (*s != '\0') {
    if (*s == '\n') {
        current_line++;
        info.now_line = 1;
    } else {
        info.now_line = 0;
      }
    s++; 
    }
    yylloc.last_line = current_line;
  }


int main(int argc, char **argv) {
  FILE *test_file = fopen(argv[1], "r");
  fseek(test_file, 0L, SEEK_END);
  buffer_size = ftell(test_file);
  rewind(test_file);
  buffer = (char*) malloc(buffer_size);
  fread(buffer, 1, buffer_size, test_file);
  position = yypstate_new();
  int status = YYPUSH_MORE;
  while (status == YYPUSH_MORE) {
    status = token_push(yylex());
  }
  yypstate_delete (position);
  fclose(test_file);
}

