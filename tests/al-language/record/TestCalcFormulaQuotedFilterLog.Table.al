// Support table for TestCalcFormulaQuotedFilterTests.Codeunit.al -- a report writes
// here from its data item body, so "which rows did the DataItemTableView admit" is
// observable from the test without reading a report instance global.
table 60305 "CFQ Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = SystemMetadata;
        }
        field(2; Marker; Text[50])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }

    procedure Log(NewMarker: Text[50])
    var
        LogRec: Record "CFQ Log";
        NextNo: Integer;
    begin
        if LogRec.FindLast() then
            NextNo := LogRec."Entry No.";
        LogRec.Init();
        LogRec."Entry No." := NextNo + 1;
        LogRec.Marker := NewMarker;
        LogRec.Insert(false);
    end;
}
