// Scope: fixture xmlport for the XMLport Metadata virtual table (2000000280)
// Fixture table: ALT Universal (60000)
//
// Every column-bearing property is set to a value that differs from the control xmlport
// "ALT Variable XmlPort" (60025: Direction = Both, Format = Xml, UseRequestPage = false), so a
// provider that answers one fixed value per column cannot satisfy both rows.

xmlport 67351 "ALT XPM Probe"
{
    Caption = 'ALT XPM Probe Caption';
    Direction = Export;
    Format = VariableText;
    TextEncoding = UTF16;
    TransactionType = Browse;
    UseRequestPage = true;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "ALT Universal")
            {
                fieldelement(EntryNo; Row."Entry No.")
                {
                }
            }
        }
    }
}
