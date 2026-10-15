// @expect AL0162 | 'OnRun' is not a valid trigger for this object type. Check the object documentation for supported triggers.
// OnRun in a table.
table 50135 "MNC T318"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
    trigger OnRun()
    begin
    end;
}
