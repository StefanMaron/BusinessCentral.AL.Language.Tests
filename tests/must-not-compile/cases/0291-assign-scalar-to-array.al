// @expect AL0145 | Direct assignment is not valid for arrays. Use array indexing to assign individual elements or a loop to copy elements.
// A scalar is assigned to a whole array.
codeunit 50104 "MNC C291"
{
    procedure Run1()
    var
        A: array[3] of Integer;
    begin
        A := 1;
    end;
}
