// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'. Use an explicit conversion or change the type.
// A procedure returning Integer exits with a Text literal.
codeunit 50085 "MNC C274"
{
    procedure Run1(): Integer
    begin
        exit('abc');
    end;
}
