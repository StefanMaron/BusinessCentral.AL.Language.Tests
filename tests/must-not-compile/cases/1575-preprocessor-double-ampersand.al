// @expect AL0631 | Single-line comment or end-of-line expected.
// Corpus #664 item 29. The preprocessor has no '&&' operator; conjunction is the word 'and' (#if BC27PLUS and BC28PLUS).
codeunit 51575 "MNC BM C1575"
{
    procedure P(): Integer
    begin
#if BC27PLUS && BC28PLUS
        exit(3);
#endif
        exit(1);
    end;
}
