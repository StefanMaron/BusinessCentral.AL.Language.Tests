codeunit 67812 "Test xRec Stamp Fields"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Recorder: Codeunit "xRec Stamp Recorder";

    [Test]
    procedure Probe_Insert()
    var
        P: Record "xRec Stamp Probe";
        T: Text;
    begin
        P.DeleteAll();
        Recorder.Wipe();
        P."Entry No." := 0;
        P.Payload := 'one';
        P.Insert(true);
        T := 'INS rec/xrec EN=' + Recorder.Read('OnInsert', 'Rec.EntryNo') + '/' + Recorder.Read('OnInsert', 'xRec.EntryNo');
        T += ' stored=' + Format(P."Entry No.");
        T += Row('Id', 'SystemId', Format(P.SystemId, 0, 9));
        T += Row('CrAt', 'SystemCreatedAt', Format(P.SystemCreatedAt, 0, 9));
        T += Row('MoAt', 'SystemModifiedAt', Format(P.SystemModifiedAt, 0, 9));
        T += Row('CrBy', 'SystemCreatedBy', Format(P.SystemCreatedBy, 0, 9));
        T += Row('MoBy', 'SystemModifiedBy', Format(P.SystemModifiedBy, 0, 9));
        T += ' pay=' + Recorder.Read('OnInsert', 'Rec.Payload') + '/' + Recorder.Read('OnInsert', 'xRec.Payload');
        Error(T);
    end;

    [Test]
    procedure Probe_Modify()
    var
        P: Record "xRec Stamp Probe";
        Pre: Text;
        T: Text;
    begin
        P.DeleteAll();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        Pre := Format(P.SystemModifiedAt, 0, 9);
        Sleep(50);
        Recorder.Wipe();
        P.Payload := 'two';
        P.Modify(true);
        T := 'MOD EN=' + Recorder.Read('OnModify', 'Rec.EntryNo') + '/' + Recorder.Read('OnModify', 'xRec.EntryNo');
        T += ' preMo=' + Pre + ' postMo=' + Format(P.SystemModifiedAt, 0, 9);
        T += ' Id' + Recorder.Classify('OnModify', 'Rec.SystemId', Format(P.SystemId, 0, 9), Format(P.SystemId, 0, 9));
        T += Recorder.Classify('OnModify', 'xRec.SystemId', Format(P.SystemId, 0, 9), Format(P.SystemId, 0, 9));
        T += ' CrAt' + Recorder.Classify('OnModify', 'Rec.SystemCreatedAt', Format(P.SystemCreatedAt, 0, 9), Format(P.SystemCreatedAt, 0, 9));
        T += Recorder.Classify('OnModify', 'xRec.SystemCreatedAt', Format(P.SystemCreatedAt, 0, 9), Format(P.SystemCreatedAt, 0, 9));
        T += ' MoAt' + Recorder.Classify('OnModify', 'Rec.SystemModifiedAt', Pre, Format(P.SystemModifiedAt, 0, 9));
        T += Recorder.Classify('OnModify', 'xRec.SystemModifiedAt', Pre, Format(P.SystemModifiedAt, 0, 9));
        T += ' CrBy' + Recorder.Classify('OnModify', 'Rec.SystemCreatedBy', Format(P.SystemCreatedBy, 0, 9), Format(P.SystemCreatedBy, 0, 9));
        T += Recorder.Classify('OnModify', 'xRec.SystemCreatedBy', Format(P.SystemCreatedBy, 0, 9), Format(P.SystemCreatedBy, 0, 9));
        T += ' MoBy' + Recorder.Classify('OnModify', 'Rec.SystemModifiedBy', Format(P.SystemModifiedBy, 0, 9), Format(P.SystemModifiedBy, 0, 9));
        T += Recorder.Classify('OnModify', 'xRec.SystemModifiedBy', Format(P.SystemModifiedBy, 0, 9), Format(P.SystemModifiedBy, 0, 9));
        T += ' pay=' + Recorder.Read('OnModify', 'Rec.Payload') + '/' + Recorder.Read('OnModify', 'xRec.Payload');
        Error(T);
    end;

    [Test]
    procedure Probe_Delete()
    var
        P: Record "xRec Stamp Probe";
        T: Text;
    begin
        P.DeleteAll();
        P.Payload := 'one';
        P.Insert(false);
        P.Get(P."Entry No.");
        Recorder.Wipe();
        P.Delete(true);
        T := 'DEL EN=' + Recorder.Read('OnDelete', 'Rec.EntryNo') + '/' + Recorder.Read('OnDelete', 'xRec.EntryNo');
        T += ' Id' + Recorder.Classify('OnDelete', 'Rec.SystemId', '', Format(P.SystemId, 0, 9));
        T += Recorder.Classify('OnDelete', 'xRec.SystemId', '', Format(P.SystemId, 0, 9));
        T += ' CrAt' + Recorder.Classify('OnDelete', 'Rec.SystemCreatedAt', '', Format(P.SystemCreatedAt, 0, 9));
        T += Recorder.Classify('OnDelete', 'xRec.SystemCreatedAt', '', Format(P.SystemCreatedAt, 0, 9));
        T += ' MoAt' + Recorder.Classify('OnDelete', 'Rec.SystemModifiedAt', '', Format(P.SystemModifiedAt, 0, 9));
        T += Recorder.Classify('OnDelete', 'xRec.SystemModifiedAt', '', Format(P.SystemModifiedAt, 0, 9));
        T += ' pay=' + Recorder.Read('OnDelete', 'Rec.Payload') + '/' + Recorder.Read('OnDelete', 'xRec.Payload');
        Error(T);
    end;

    local procedure Row(Tag: Text; What: Text; Stored: Text): Text
    begin
        exit(' ' + Tag + Recorder.Classify('OnInsert', 'Rec.' + What, '', Stored) + Recorder.Classify('OnInsert', 'xRec.' + What, '', Stored));
    end;
}
