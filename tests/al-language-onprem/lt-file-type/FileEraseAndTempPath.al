// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); File.Erase of an empty name (full error text) and File.IsPathTemporary for the temporary path, a file in it, relative, empty and drive-letter paths (issue 581 items 4 and 5)
// BC versions: 27+
codeunit 61275 "LT File Erase And Temp Path"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TErase(P: Text)
    begin
        File.Erase(P);
    end;

    [TryFunction]
    local procedure TIsTemp(P: Text; var R: Boolean)
    begin
        R := File.IsPathTemporary(P);
    end;

    local procedure EraseCase(var Observer: Codeunit "Probe Observer"; Name: Text; P: Text)
    begin
        if TErase(P) then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe(Name, 'error');
            Observer.ObserveError(Name + '_error');
        end;
    end;

    local procedure TempCase(var Observer: Codeunit "Probe Observer"; Name: Text; P: Text)
    var
        R: Boolean;
    begin
        if TIsTemp(P, R) then
            Observer.Observe(Name, '[' + P + '] ' + Format(R))
        else begin
            Observer.Observe(Name, 'error');
            Observer.ObserveError(Name + '_error');
        end;
    end;

    [Test]
    procedure Erase_EmptyName_FullErrorText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EraseCase(Observer, 'empty', '');
        EraseCase(Observer, 'blank', ' ');
        Observer.Observe('exists_empty', Format(File.Exists('')));
        Observer.Finish();
    end;

    [Test]
    procedure IsPathTemporary_Paths()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Text;
    begin
        Temp := TemporaryPath();
        Observer.Observe('temporary_path_ends_with_separator', Format(Temp.EndsWith('/') or Temp.EndsWith('\')));
        TempCase(Observer, 'temporary_path', Temp);
        TempCase(Observer, 'file_in_temporary_path', Temp + 'lt-ispathtemp.tmp');
        TempCase(Observer, 'subfolder_file_in_temporary_path', Temp + 'lt-sub/lt-ispathtemp.tmp');
        TempCase(Observer, 'relative', 'lt-relative.tmp');
        TempCase(Observer, 'relative_subfolder', 'lt-sub/lt-relative.tmp');
        TempCase(Observer, 'empty', '');
        TempCase(Observer, 'blank', ' ');
        TempCase(Observer, 'other_drive_c', 'C:\lt-other.tmp');
        TempCase(Observer, 'other_drive_d', 'D:\lt-other.tmp');
        TempCase(Observer, 'other_drive_z_slash', 'Z:/lt-other.tmp');
        TempCase(Observer, 'unc', '\\lt-server\share\lt-other.tmp');
        TempCase(Observer, 'root', '/');
        Observer.Finish();
    end;
}
