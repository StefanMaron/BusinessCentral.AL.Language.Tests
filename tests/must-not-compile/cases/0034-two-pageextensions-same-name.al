// @expect AL0197 | An application object of type 'PageExtension' with name 'MNC Same Ext Name' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0197 | An application object of type 'PageExtension' with name 'MNC Same Ext Name' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two page extensions of one name.
table 50000 "MNC Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC Base Page"
{
    PageType = Card;
    SourceTable = "MNC Table";
}

pageextension 50002 "MNC Same Ext Name" extends "MNC Base Page"
{
}

pageextension 50003 "MNC Same Ext Name" extends "MNC Base Page"
{
}
