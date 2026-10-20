// @expect AL0298 | The data type of the expression assigned to the 'StyleExpr' property is not valid. Valid data types are Boolean, Text, or Code.
// StyleExpr set to a variable of the type PageStyle (microsoft/AL issue 8031): refused. A Text variable works (types/lt-page-style/PageStyle.al).
table 51432 "MNC BP T1432"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51432 "MNC BP P1432"
{
    PageType = Card;
    SourceTable = "MNC BP T1432";

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { StyleExpr = StyleVar; }
        }
    }

    var
        StyleVar: PageStyle;
}
