// @expect AL0582 | 'MNC C1768' does not implement the interface member 'MNC I1768.Fill'.
// The interface declares a `var ... temporary` record parameter; the implementation in the same app omits `temporary`.
// Corpus issue 670 (lead: microsoft/AL issues 6156 and 5675). With `temporary` the implementation compiles
// (see tests/al-language/misc/lt-cv-odd-leads/CvInterfaceShapes.al).
interface "MNC I1768"
{
    procedure Fill(var TempBuf: Record "MNC T1768" temporary);
}

table 50000 "MNC T1768"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50000 "MNC C1768" implements "MNC I1768"
{
    procedure Fill(var TempBuf: Record "MNC T1768")
    begin
    end;
}
