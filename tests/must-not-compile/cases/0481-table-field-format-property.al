// @expect AL0124 | The property 'Format' cannot be used in this context. Verify the property is available for the current object type.
// The Format property is written on a table field (the C/AL property of a field; AL has no such property on a table field).
table 59901 "MNC FieldFormat 0481"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal)
        {
            Format = '<Sign><Integer><Decimals><Comma,.>';
        }
    }
}
