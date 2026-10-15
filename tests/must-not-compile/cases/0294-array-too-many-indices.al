// @expect AL0144 | Wrong number of indices inside []; expected 1
// A one-dimensional array is indexed with two indices.
codeunit 50107 "MNC C294"
{
    procedure Run1()
    var
        A: array[3] of Integer;
    begin
        A[1, 2] := 1;
    end;
}
