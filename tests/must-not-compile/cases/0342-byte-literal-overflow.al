// @expect AL0369 | Constant value '256' cannot be converted to a 'Byte'.
// A Byte variable assigned 256.
codeunit 50160 "MNC C342"
{
    procedure Run1()
    var
        B: Byte;
    begin
        B := 256;
    end;
}
