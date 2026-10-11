codeunit 67812 "Test xRec Stamp Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Recorder: Codeunit "xRec Stamp Recorder";

    [Test]
    procedure Probe_Dump()
    var
        P: Record "xRec Stamp Probe";
        Stored: Text;
    begin
        P.DeleteAll();
        Recorder.Wipe();

        P.Init();
        P."Entry No." := 0;
        P.Payload := 'one';
        P.Insert(true);
        Stored := 'AfterInsert: EntryNo=<' + Format(P."Entry No.", 0, 9) + '> SystemId=<' + Format(P.SystemId, 0, 9) + '> CreatedAt=<' + Format(P.SystemCreatedAt, 0, 9) + '> ModifiedAt=<' + Format(P.SystemModifiedAt, 0, 9) + '> CreatedBy=<' + Format(P.SystemCreatedBy, 0, 9) + '>. ';
        Stored += 'INSERT TRIGGER: ' + Recorder.Dump();

        Recorder.Wipe();
        P.Get(P."Entry No.");
        Stored += 'AfterGet: ModifiedAt=<' + Format(P.SystemModifiedAt, 0, 9) + '>. ';
        Sleep(50);
        P.Payload := 'two';
        P.Modify(true);
        Stored += 'AfterModify: ModifiedAt=<' + Format(P.SystemModifiedAt, 0, 9) + '>. ';
        Stored += 'MODIFY TRIGGER: ' + Recorder.Dump();

        Recorder.Wipe();
        P.Get(P."Entry No.");
        P.Delete(true);
        Stored += 'DELETE TRIGGER: ' + Recorder.Dump();
        Error('PROBE %1', Stored);
    end;
}
