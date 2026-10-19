// @expect AL0132 | 'PromptMode' does not contain a definition for 'Lookup'
// CurrPage.PromptMode is set to PromptMode::Lookup in OnOpenPage of a PromptDialog page: PromptMode has no member Lookup.
table 51090 "MNC AN T1090"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

page 51090 "MNC AN P1090"
{
    PageType = PromptDialog;
    Extensible = false;
    SourceTable = "MNC AN T1090";
    SourceTableTemporary = true;

    layout
    {
        area(Prompt)
        {
            field(Id; Rec.Id) { }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.PromptMode := PromptMode::Lookup;
    end;
}
