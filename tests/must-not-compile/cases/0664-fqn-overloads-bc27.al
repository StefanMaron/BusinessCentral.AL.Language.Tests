// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// @expect AL0132 | 'RecordRef' does not contain a definition for 'FullyQualifiedName'
// @until 27
// Report.Run, Report.RunModal, Report.Execute, Page.Run, RecordRef.Open with the fully qualified name of the object and RecordRef.FullyQualifiedName exist from BC 28 (runtime 17.0): BC 27 rejects them.
report 50000 "MNC T Fqn Report"
{
    UseRequestPage = false;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(Number; Number) { }
        }
    }
}

page 50002 "MNC T Fqn Page"
{
    PageType = List;
    SourceTable = Integer;
}

codeunit 50001 "MNC T Fqn Calls"
{
    procedure Calls()
    var
        RecRef: RecordRef;
        Row: Record Integer;
    begin
        Report.Run('MNC T Fqn Report');
        Report.RunModal('MNC T Fqn Report');
        Report.Execute('MNC T Fqn Report', '');
        Page.Run('MNC T Fqn Page', Row, 1);
        RecRef.Open('MNC T Fqn Page');
        Message(RecRef.FullyQualifiedName());
    end;
}
