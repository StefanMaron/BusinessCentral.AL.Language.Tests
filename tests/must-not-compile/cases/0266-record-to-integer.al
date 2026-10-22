// @expect AL0122 | Cannot implicitly convert type 'Record "MNC T266"' to 'Integer'. Use an explicit conversion or change the type.
// A Record is assigned to an Integer.
table 50075 "MNC T266"
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

codeunit 50076 "MNC C266"
{
    procedure Run1()
    var
        R: Record "MNC T266";
        I: Integer;
    begin
        I := R;
    end;
}
