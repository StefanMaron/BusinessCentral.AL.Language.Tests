// @expect AL0124 | The property 'InitValue' cannot be used in this context. Verify the property is available for the current object type.
// InitValue on a page field.
table 50131 "MNC T315"
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

page 50132 "MNC P315"
{
    PageType = List;
    SourceTable = "MNC T315";
    layout
    {
        area(Content)
        {
            repeater(Rep)
            {
                field(Id; Rec.Id) { ApplicationArea = All; InitValue = 5; }
            }
        }
    }
}
