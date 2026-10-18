// @expect AL0666 | 'Run' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @expect AL0666 | 'RunModal' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @expect AL0666 | 'Execute' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @expect AL0666 | 'Run' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @expect AL0666 | 'Open' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @expect AL0666 | 'FullyQualifiedName' is not available in runtime version '16.1'. The supported runtime versions are: '17.0' or greater.
// @until 27
// The fully qualified name overloads of Report.Run, Report.RunModal, Report.Execute, Page.Run and RecordRef.Open and RecordRef.FullyQualifiedName need runtime 17.0: the BC 27 app runtime is 16.1 and cannot call them (the BC 28 and 29 apps run on 17.1 and 18.0, where tests/al-language pins them).
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
