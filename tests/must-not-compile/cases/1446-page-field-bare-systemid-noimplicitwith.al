// @expect AL0118 | The name 'SystemId' does not exist in the current context.
// @appjson {"features": ["NoImplicitWith"]}
// A page field whose source is the bare name SystemId (microsoft/AL issue 5507) in an app with the feature NoImplicitWith: AL0118.
// Without the feature the same page compiles (warning AL0604) and the field shows the record's SystemId: positive test in
// tests/al-language/pages/lt-page-controls-aa/AaControls.al (AA_BP_Page_BareSystemIdField).
table 51446 "MNC BP T1446"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51446 "MNC BP P1446"
{
    PageType = Card;
    SourceTable = "MNC BP T1446";

    layout
    {
        area(Content)
        {
            field(SystemId; SystemId) { }
        }
    }
}
