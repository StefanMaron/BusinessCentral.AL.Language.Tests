// @expect AL0124 | The property 'Width' cannot be used in this context. Verify the property is available for the current object type.
// Width is not a property of a report column.
table 59701 "MNC U 701" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
report 59702 "MNC U Rep 701"
{
    ProcessingOnly = false;
    dataset { dataitem(Row; "MNC U 701") { column(Id; Id) { Width = 5; } } }
}
