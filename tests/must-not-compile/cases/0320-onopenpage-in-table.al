// @expect AL0162 | 'OnOpenPage' is not a valid trigger for this object type. Check the object documentation for supported triggers.
// OnOpenPage in a table.
table 50137 "MNC T320"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
    trigger OnOpenPage()
    begin
    end;
}
