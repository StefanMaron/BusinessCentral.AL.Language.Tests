// @expect AL0122 | Cannot implicitly convert type 'DateTime' to 'Date'. Use an explicit conversion or change the type.
// Writer PY-C (al-runtime-rs PR 339, probes-needed "Ternary and call-argument conversion"): a conditional expression with a Date true branch
// and a DateTime false branch. The reverse order (DateTime true, Date false) is case 1406.
codeunit 51872 "MNC PYC Ternary Date DT"
{
    procedure Run1()
    var
        Cond: Boolean;
        D: Date;
        DT: DateTime;
        V: Variant;
    begin
        V := Cond ? D : DT;
    end;
}
