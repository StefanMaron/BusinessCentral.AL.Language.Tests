// @expect AL0666 | 'Run' is not available in runtime version '16.1'
// @expect AL0666 | 'RunModal' is not available in runtime version '16.1'
// @expect AL0666 | 'Run' is not available in runtime version '16.1'
// @until 27
// On BC 27 (runtime 16.1) the compiler picks the fully qualified name overloads of runtime 17 and reports them instead; BC 28 and 29: case 1634.
// Page.Run, Page.RunModal and Report.Run with a RecordRef in the place of the record (microsoft/AL issue 584).
table 51633 "MNC CE Row 1633"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 51633 "MNC CE List 1633"
{
    PageType = List;
    SourceTable = "MNC CE Row 1633";
    layout { area(Content) { repeater(R) { field(Id; Rec.Id) { } } } }
}
report 51633 "MNC CE Report 1633"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC CE Row 1633") { } }
}
codeunit 51634 "MNC CE Run 1633"
{
    procedure RunWithRecRef()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(Database::"MNC CE Row 1633");
        Page.Run(Page::"MNC CE List 1633", RecRef);
        Page.RunModal(Page::"MNC CE List 1633", RecRef);
        Report.Run(Report::"MNC CE Report 1633", false, false, RecRef);
    end;
}
