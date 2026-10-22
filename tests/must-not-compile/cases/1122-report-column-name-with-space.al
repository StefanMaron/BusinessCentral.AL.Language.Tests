// @expect AL0379 | The name 'Par Code' cannot be used as an identifier because it does not comply with the Common Language Specification
// A report column name with a space (a quoted identifier) is refused; a data item name with a space is accepted (corpus issue 646, item 19).
report 51123 "MNC AQ Report 51123"
{
    UsageCategory = None;

    dataset
    {
        dataitem("Par Item"; Integer)
        {
            column("Par Code"; Number) { }
        }
    }
}
