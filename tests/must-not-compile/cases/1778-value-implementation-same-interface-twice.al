// @expect AL0675 | An implementation for the interface 'Interface' is already specified in this list.
// Corpus #670 item 63 (AL issue 6175). An enum value's Implementation that lists the same interface twice is refused with AL0675 on
// BC 27, 28 and 29. DefaultImplementation form: case 1777.
interface "MNC CW I1778"
{
    procedure Work(): Text;
}

codeunit 51778 "MNC CW C1778A" implements "MNC CW I1778"
{
    procedure Work(): Text
    begin
        exit('A');
    end;
}

codeunit 51779 "MNC CW C1778B" implements "MNC CW I1778"
{
    procedure Work(): Text
    begin
        exit('B');
    end;
}

enum 51778 "MNC CW E1778" implements "MNC CW I1778"
{
    Extensible = true;
    value(0; Zero) { Implementation = "MNC CW I1778" = "MNC CW C1778A", "MNC CW I1778" = "MNC CW C1778B"; }
}
