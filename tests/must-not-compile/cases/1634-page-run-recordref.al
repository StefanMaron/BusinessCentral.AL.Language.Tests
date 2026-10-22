// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 2: cannot convert from 'RecordRef' to 'Table'
// @expect AL0133 | Argument 4: cannot convert from 'RecordRef' to 'var Table'
// @from 28
// BC 27: case 1633. A Variant that holds a RecordRef compiles: see tests/al-language/pages/lt-ce-page-run/CePageRun.al.
// Page.Run, Page.RunModal and Report.Run with a RecordRef in the place of the record (microsoft/AL issue 584).
table 51634 "MNC CE Row 1634"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51634 "MNC CE List 1634"
{
    PageType = List;
    SourceTable = "MNC CE Row 1634";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 51634 "MNC CE Report 1634"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC CE Row 1634") { } }
}
codeunit 51635 "MNC CE Run 1634"
{
    procedure RunWithRecRef()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"MNC CE Row 1634");
        Page.Run(Page::"MNC CE List 1634", RecRef);
        Page.RunModal(Page::"MNC CE List 1634", RecRef);
        Report.Run(Report::"MNC CE Report 1634", false, false, RecRef);
    end;
}
