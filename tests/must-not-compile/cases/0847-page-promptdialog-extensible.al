// @expect AL0223 | The property 'PromptDialog' can only be used if the property 'Extensible' is set to 'False'
// A PromptDialog page must set Extensible = false.
table 59847 "MNC Z Row 0847"
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
page 52847 "MNC Z Prompt 0847"
{
    PageType = PromptDialog;
    PromptMode = Prompt;
    layout { area(Prompt) { field(Nm; Nm) { } } }
    var Nm: Text;
}
