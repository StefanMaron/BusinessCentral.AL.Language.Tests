// @expect AL0118 | The name 'Rec' does not exist in the current context.
// Rec in the OnOpenPage trigger of an xmlport request page that declares no SourceTable (with SourceTable it compiles: xmlport/lt-y-xmlport-props/YXmlPortProps.al, xmlport 88570).
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
        trigger OnOpenPage()
        begin
            Rec.Modify();
        end;
    }
}
