// @expect AL0118 | The name 'Rec' does not exist in the current context.
// Rec in the OnPreXmlPort trigger of an xmlport that has no request page (with a request page SourceTable it compiles: xmlport/lt-y-xmlport-props/YXmlPortProps.al, xmlport 88570).
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

    trigger OnPreXmlPort()
    begin
        Rec.Id := 1;
    end;
}
