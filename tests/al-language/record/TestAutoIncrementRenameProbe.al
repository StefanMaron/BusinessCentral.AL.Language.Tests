// PROBE -- records what a real service tier answers; replaced by assertions once measured.
codeunit 67837 "Probe AutoInc Rename"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: TextBuilder;

    local procedure Note(What: Text; Value: Text)
    begin
        Trace.Append(What + '=' + Value + '; ');
    end;

    local procedure Done(CaseName: Text; RowsText: Text)
    begin
        Error('PROBE %1 :: %2 rows=[%3]', CaseName, Trace.ToText(), RowsText);
    end;

    // R1: Rename of a composite key that leaves the AutoIncrement field alone.
    [Test]
    procedure Probe_R1_RenameCodeOnly()
    var
        C: Record "AutoInc Edge Composite";
        K: Integer;
    begin
        Clear(Trace);
        C.DeleteAll();
        C.Code := 'A';
        C.Insert(true);
        K := C."Entry No.";
        Note('ins.key', Format(K, 0, 9));
        C.Get(K, 'A');
        asserterror begin C.Rename(K, 'B'); Error('RENAME-OK'); end;
        Note('rename.err', GetLastErrorText());
        Note('rec.key', Format(C."Entry No.", 0, 9) + '/' + C.Code);
        Done('R1', Format(C.Count()));
    end;

    // R2: Rename that changes the AutoIncrement field of a composite key.
    [Test]
    procedure Probe_R2_RenameEntryNo()
    var
        C: Record "AutoInc Edge Composite";
        K: Integer;
    begin
        Clear(Trace);
        C.DeleteAll();
        C.Code := 'A';
        C.Insert(true);
        K := C."Entry No.";
        C.Get(K, 'A');
        asserterror begin C.Rename(K + 50, 'A'); Error('RENAME-OK'); end;
        Note('rename.err', GetLastErrorText());
        Done('R2', Format(C.Count()));
    end;
}
