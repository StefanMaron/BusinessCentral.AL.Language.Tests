// @expect AL0169 | The option value 'Other' is not valid. Check the enum definition for valid values.
// PromptMode knows Prompt, Content and Generate only.
table 59846 "MNC Z Row 0846"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Opt; Option) { OptionMembers = A,B; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
page 52846 "MNC Z Prompt 0846"
{
    PageType = PromptDialog;
    Extensible = false;
    PromptMode = Other;
    layout { area(Prompt) { field(Nm; Nm) { } } }
    var Nm: Text;
}
