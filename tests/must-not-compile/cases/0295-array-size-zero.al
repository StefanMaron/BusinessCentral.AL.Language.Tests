// @expect AL0147 | An array dimension must be a positive number. Use a positive integer value for the array size (e.g., [10]).
// An array is declared with size 0.
codeunit 50108 "MNC C295"
{
    procedure Run1()
    var
        A: array[0] of Integer;
    begin
    end;
}
