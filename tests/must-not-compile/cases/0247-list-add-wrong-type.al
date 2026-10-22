// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// A Text is added to a List of Integer.
codeunit 50053 "MNC C247"
{
    procedure Run1()
    var
        L: List of [Integer];
    begin
        L.Add('abc');
    end;
}
