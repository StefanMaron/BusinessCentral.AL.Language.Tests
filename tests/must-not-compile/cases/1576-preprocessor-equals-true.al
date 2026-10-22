// @expect AL0629 | Preprocessor expression is not valid.
// Corpus #664 item 29. A preprocessor expression has no comparison operators: '#if BC27PLUS == true' is refused.
codeunit 51576 "MNC BM C1576"
{
    procedure P(): Integer
    begin
#if BC27PLUS == true
        exit(3);
#endif
        exit(1);
    end;
}
