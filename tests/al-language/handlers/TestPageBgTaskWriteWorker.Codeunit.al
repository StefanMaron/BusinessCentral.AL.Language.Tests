// Worker codeunit for TestPageBgTask_Tests.al's session-isolation probes: writes to the
// SAME table the page's TestPage caller reads, run inside a page background task. Uses
// TryFunction so a write refused by the platform (e.g. a read-only child session) reports
// back through the normal Results dictionary instead of surfacing as an unhandled error --
// the point of these tests is to OBSERVE what real BC does, not to assume it errors or
// succeeds.

codeunit 60794 "Test Page BgTask WriteWorker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Op: Text;
        RowNo: Text;
        Outcome: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Params.Get('Op', Op);
        Params.Get('No', RowNo);

        case Op of
            'Insert':
                if TryInsertRow(CopyStr(RowNo, 1, 20)) then
                    Outcome := 'OK'
                else
                    Outcome := 'ERROR:' + GetLastErrorText();
            'Modify':
                if TryModifyRow(CopyStr(RowNo, 1, 20)) then
                    Outcome := 'OK'
                else
                    Outcome := 'ERROR:' + GetLastErrorText();
        end;

        Results.Add('Outcome', Outcome);
        Page.SetBackgroundTaskResult(Results);
    end;

    [TryFunction]
    local procedure TryInsertRow(RowNo: Code[20])
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Init();
        Row."No." := RowNo;
        Row.Name := 'WRITTEN-BY-WORKER';
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryModifyRow(RowNo: Code[20])
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Get(RowNo);
        Row.Name := 'MODIFIED-BY-WORKER';
        Row.Modify();
    end;
}
