// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: fixture query used by query coverage tests
// Fixture table: ALT Universal (60000)

query 60022 "ALT Universal Query"
{
    QueryType = Normal;
    OrderBy = ascending(EntryNo);

    elements
    {
        dataitem(Universal; "ALT Universal")
        {
            column(EntryNo; "Entry No.")
            {
                Caption = 'Entry No.';
            }
            column(IntegerValue; "Integer Field")
            {
                Caption = 'Integer Value';
            }
            column(TextValue; "Text Field")
            {
                Caption = 'Text Value';
            }
        }
    }
}
