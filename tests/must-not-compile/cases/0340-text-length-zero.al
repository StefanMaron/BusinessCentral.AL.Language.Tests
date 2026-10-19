// @expect AL0581 | The length for the type 'Text' must be positive
// A Text variable with length 0.
codeunit 50158 "MNC C340"
{
    procedure Run1()
    var
        T: Text[0];
    begin
    end;
}
