// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Field' of 'SetRange(Joker, [Joker], [Joker])'
// Record.SetRange is called without arguments.
table 50059 "MNC T253"
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

codeunit 50060 "MNC C253"
{
    procedure Run1()
    var
        R: Record "MNC T253";
    begin
        R.SetRange();
    end;
}
