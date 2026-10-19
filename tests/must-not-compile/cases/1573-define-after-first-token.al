// @expect AL0625 | Cannot define/undefine preprocessor symbols after first token in file.
// Corpus #664 item 29. #define (and #undef) must come before the first token of a file; inside a procedure body it is refused.
// The positive half (file scope of #define and #undef, not, and, or, parentheses) is tests/al-language/misc/lt-bm-preprocessor-scope.
codeunit 51573 "MNC BM C1573"
{
    procedure P(): Integer
    begin
#define LATE
        exit(1);
    end;
}
