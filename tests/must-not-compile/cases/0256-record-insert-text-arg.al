// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Boolean'
// Record.Insert is called with a Text argument.
table 50063 "MNC T256"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50064 "MNC C256"
{
    procedure Run1()
    var
        R: Record "MNC T256";
    begin
        R.Insert('x');
    end;
}
