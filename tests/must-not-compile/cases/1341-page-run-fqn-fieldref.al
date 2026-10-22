// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0133 | Argument 3: cannot convert from 'FieldRef' to 'Integer'
// @from 28
// Page.Run has no overload that takes a fully qualified name and a FieldRef (Page.RunModal has one, see
// tests/al-language/report/lt-t-fqn-run/LtTFqnRun.al). The compiler picks the by-number FieldRef form and rejects both arguments.
// BC 27 (runtime 16.1) rejects the fully qualified name overloads anyway (case 0664).
namespace MNC.BJ.Fqn;

table 50000 "MNC BJ Fqn Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

page 50001 "MNC BJ Fqn Card"
{
    PageType = Card;
    SourceTable = "MNC BJ Fqn Row";
}

codeunit 50002 "MNC BJ Fqn Run"
{
    procedure Probe()
    var
        Row: Record "MNC BJ Fqn Row";
        RecRef: RecordRef;
        FRef: FieldRef;
    begin
        RecRef.GetTable(Row);
        FRef := RecRef.Field(1);
        Page.Run('MNC.BJ.Fqn.MNC BJ Fqn Card', Row, FRef);
    end;
}
