// @expect AL0118 | The name 'Undeclared' does not exist in the current context.
// A query trigger uses an undeclared variable.
table 50012 "MNC T209"
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

query 50013 "MNC Q209"
{
    elements
    {
        dataitem(T; "MNC T209")
        {
            column(Id; Id) { }
        }
    }
    trigger OnBeforeOpen()
    begin
        Undeclared := 5;
    end;
}
