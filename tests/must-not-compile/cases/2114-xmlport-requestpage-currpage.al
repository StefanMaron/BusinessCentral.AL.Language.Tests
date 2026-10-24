// @expect AL0118 | The name 'CurrPage' does not exist in the current context.
// CurrPage in the OnOpenPage trigger of an xmlport request page with SourceTable (Rec compiles there: xmlport/lt-y-xmlport-props/YXmlPortProps.al, xmlport 88570).
table 50000 "MNC RS Table"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

xmlport 50001 "MNC RS XmlPort"
{
    schema
    {
        textelement(Root) { }
    }

    requestpage
    {
        SourceTable = "MNC RS Table";

        trigger OnOpenPage()
        begin
            CurrPage.Update(false);
        end;
    }
}
