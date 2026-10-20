// @expect AL0408 | The type 'Blob' cannot be used as a type argument in this context.
// Corpus issue 670 item 14: List of [Blob] is refused.
codeunit 50749 "MNC C1749"
{
    procedure Run1()
    var
        L: List of [Blob];
    begin
    end;
}
