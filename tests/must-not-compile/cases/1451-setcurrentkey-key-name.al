// @expect AL0118 | The name 'ByName' does not exist in the current context.
// Record.SetCurrentKey takes fields, not the name of a key: a key name that is not also a field name is unknown (microsoft/AL issues 130
// and 210; corpus issue 668).
table 50452 "MNC T1451"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

codeunit 50453 "MNC C1451"
{
    procedure Run1()
    var
        R: Record "MNC T1451";
    begin
        R.SetCurrentKey(ByName);
    end;
}
