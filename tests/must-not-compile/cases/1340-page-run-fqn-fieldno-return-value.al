// @expect AL0122 | Cannot implicitly convert type 'None' to 'Boolean'.
// @from 28
// Page.Run(FullyQualifiedName, Record, FieldNo) returns nothing: its result cannot be assigned. Positive test without the result:
// tests/al-language/report/lt-bj-fqn-page-run/BjFqnPageRun.al. BC 27 (runtime 16.1) rejects the overload itself (case 0664).
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
        Ok: Boolean;
    begin
        Ok := Page.Run('MNC.BJ.Fqn.MNC BJ Fqn Card', Row, 1);
    end;
}
