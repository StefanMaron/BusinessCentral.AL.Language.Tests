// @expect AL0122 | Cannot implicitly convert type 'Code' to 'Char'. Use an explicit conversion or change the type.
// Writer PY-C (al-runtime-rs PR 341, probes-needed "Text literal on the left of in with a range"): a one-character text literal is a Char, so
// a range whose ends are Code variables does not convert (case 1873 is the Text form).
codeunit 51874 "MNC PYC Char In Code Range"
{
    procedure Run1()
    var
        CLo: Code[10];
        CHi: Code[10];
        B: Boolean;
    begin
        B := 'K' in [CLo .. CHi];
    end;
}
