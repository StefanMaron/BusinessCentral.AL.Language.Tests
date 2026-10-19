// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC E1769 Other"' to 'Interface "MNC I1769"'. Use an explicit conversion or change the type.
// An interface variable assigned from a field of an enum that does not implement the interface.
// Corpus issue 670 (lead: microsoft/AL issue 5926). An enum FlowField of the implementing enum compiles
// (see tests/al-language/misc/lt-cv-odd-leads/CvInterfaceShapes.al).
interface "MNC I1769"
{
    procedure Name(): Text;
}

enum 50000 "MNC E1769 Other"
{
    value(0; Zero) { }
}

table 50000 "MNC T1769"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Other; Enum "MNC E1769 Other") { }
    }
}

codeunit 50000 "MNC C1769"
{
    procedure Go()
    var
        R: Record "MNC T1769";
        I: Interface "MNC I1769";
    begin
        I := R.Other;
    end;
}
