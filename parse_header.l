%{
/*
   Copyright 2013 Kaoru Yanase (https://github.com/kaoru2010/)

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
%}

%option noyywrap reentrant stack nounput
%x VALUE
%x TRANSFER_ENCODING
%x CONTENT_LENGTH
%x CONNECTION

%{
typedef struct request_rec {
    int content_length;
    int chunked;
    int keep_alive;
} request_rec;
%}
%option extra-type="struct request_rec *"

DELIMITER [ \t]*:[ \t]*
ANY       [^\r\n]*
%%

%{
%}

(?i:Transfer-Encoding){DELIMITER}  yy_push_state(TRANSFER_ENCODING, yyscanner);
(?i:Content-Length){DELIMITER}     yy_push_state(CONTENT_LENGTH, yyscanner);
(?i:Connection){DELIMITER}         yy_push_state(CONNECTION, yyscanner);
[^ \t:]+{DELIMITER}                yy_push_state(VALUE, yyscanner);
<VALUE>{
    {ANY}           { printf("value=%s\n", yytext); }
}
<TRANSFER_ENCODING>{
    chunked         { yyextra->chunked = 1; printf("****CHUNKED****\n"); }
    {ANY}           { printf("value=%s\n", yytext); }
}
<CONTENT_LENGTH>{
    [0-9]+       { yyextra->content_length = atoi(yytext); printf("*****%d*****\n", yyextra->content_length); }
    {ANY}        { printf("value=%s\n", yytext); }
}
<CONNECTION>{
    keep-alive  { yyextra->keep_alive = 1; printf("****KEEP-ALIVE****\n"); }
    close       { yyextra->keep_alive = 0; printf("****CLOSE****\n"); }
    {ANY}        { printf("value=%s\n", yytext); }
}
<*>{
    [ \t]+          ;
    [\r\n]+         yy_pop_state(yyscanner);
}
%%

void parse_header(const char *buf, size_t len)
{
    request_rec r = { -1 };

    yyscan_t scanner;
    yylex_init(&scanner);
    yylex_init_extra(&r, &scanner);
    YY_BUFFER_STATE bs = yy_scan_bytes(buf, len, scanner);
    yylex(scanner);
    yy_delete_buffer(bs, scanner);
    yylex_destroy(scanner);
}
