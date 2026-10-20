// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
// Writer PY-C (al-runtime-rs PR 341, probes-needed "Text literal on the left of in with a range"): a one-character text literal is a Char, so
// a range whose ends are Text variables (or a literal and a Text variable) does not convert. A longer literal compiles
// (types/lt-ax-text-format-dates/AxCodeCompare.al PYC_InRange_TextLiteralOnTheLeft).
codeunit 51873 "MNC PYC Char In Text Range"
{
    procedure Run1()
    var
        TLo: Text;
        THi: Text;
        B: Boolean;
    begin
        B := 'K' in [TLo .. THi];
        B := 'K' in ['a' .. THi];
    end;
}
