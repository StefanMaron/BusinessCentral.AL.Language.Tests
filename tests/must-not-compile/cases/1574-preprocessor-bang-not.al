// @expect AL0629 | Preprocessor expression is not valid.
// @expect AL0631 | Single-line comment or end-of-line expected.
// Corpus #664 item 29. The preprocessor has no '!' operator; negation is the word 'not' (#if not BC27PLUS).
codeunit 51574 "MNC BM C1574"
{
    procedure P(): Integer
    begin
#if !BC27PLUS
        exit(3);
#endif
        exit(1);
    end;
}
