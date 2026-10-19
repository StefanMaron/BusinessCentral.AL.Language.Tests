// @expect AL0193 | Argument 2: cannot convert from 'array[3] of Integer' to the type of Argument 1 'array[2, 3] of Integer'
// CopyArray with a two-dimensional destination and a one-dimensional source (corpus issue 645 item 18). A row of the
// two-dimensional array as the destination (CopyArray(A[2], S, 1)) compiles; see misc/lt-au-language-edges.
codeunit 51162 "MNC AU C1162"
{
    procedure Probe()
    var
        A: array[2, 3] of Integer;
        S: array[3] of Integer;
    begin
        CopyArray(A, S, 1);
    end;
}
