// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'Boolean'. Use an explicit conversion or change the type.
// An Integer is assigned to a Boolean field of a record.
codeunit 59450 "MNC P79 0450"
{
    procedure Run1()
    var
        Rec: Record "MNC P79 Rec 0450";
        I: Integer;
    begin
        Rec.Flag := I;
    end;
}

table 59600 "MNC P79 Rec 0450"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Flag; Boolean) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
