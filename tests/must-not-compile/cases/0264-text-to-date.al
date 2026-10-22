// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Date'. Use an explicit conversion or change the type.
// A Text is assigned to a Date.
codeunit 50073 "MNC C264"
{
    procedure Run1()
    var
        T: Text;
        D: Date;
    begin
        D := T;
    end;
}
