// @expect AL0675 | An implementation for the interface 'Interface' is already specified in this list.
// Corpus #670 item 63 (AL issue 6175). DefaultImplementation that lists the same interface twice is refused with AL0675 on BC 27, 28
// and 29 (the text names 'Interface', not the interface). DefaultImplementation = I = A together with a value's Implementation = I = B
// compiles: tests/al-language/codeunit/lt-cw-interface-leads/CwInterfaceLeads.al pins which codeunit runs. Value form: case 1778.
interface "MNC CW I1777"
{
    procedure Work(): Text;
}

codeunit 51776 "MNC CW C1777A" implements "MNC CW I1777"
{
    procedure Work(): Text
    begin
        exit('A');
    end;
}

codeunit 51777 "MNC CW C1777B" implements "MNC CW I1777"
{
    procedure Work(): Text
    begin
        exit('B');
    end;
}

enum 51776 "MNC CW E1777" implements "MNC CW I1777"
{
    Extensible = true;
    DefaultImplementation = "MNC CW I1777" = "MNC CW C1777A", "MNC CW I1777" = "MNC CW C1777B";
    value(0; Zero) { }
}
