// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Code[20]' which is shorter than the converted textual representation of a 'Guid'.
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Code[20]' which is shorter than the converted textual representation of a 'Guid'.
// Corpus issue 670 item 81 (microsoft/AL#7143): a Guid (a variable or a record's SystemId) assigned to a Code[20] is refused at compile time.
// A Code[38] or longer takes it (record/lt-record-conversion-assumptions/Guid_GuidAssignText_risky.al uses Code[50]). The text form through a
// Text variable fails when it runs: tests/al-language/misc/lt-cx-odd-leads/CxScalars.al, GuidText_ToCode20.
table 50785 "MNC T1785"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50785 "MNC C1785"
{
    procedure Probe()
    var
        Row: Record "MNC T1785";
        G: Guid;
        C: Code[20];
        Wide: Code[38];
    begin
        C := Row.SystemId;
        C := G;
        Wide := G;
    end;
}
