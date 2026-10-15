// @expect AL0124 | The property 'ApplicationArea' cannot be used in this context. Verify the property is available for the current object type.
// ApplicationArea on a table.
table 50122 "MNC T306"
{
    ApplicationArea = All;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
