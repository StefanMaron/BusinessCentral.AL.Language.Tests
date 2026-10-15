// @expect AL0124 | The property 'PageType' cannot be used in this context. Verify the property is available for the current object type.
// PageType on a table.
table 50124 "MNC T308"
{
    PageType = List;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
