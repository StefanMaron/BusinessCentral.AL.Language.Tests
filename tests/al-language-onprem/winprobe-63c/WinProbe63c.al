// Windows check for bump 63 (probe branch only, not for the corpus).
// Exact copies of the calls in P110_InvalidPaths (FileErrors.al:215) and O_Blob_Export_InvalidPath_Import_MissingFile
// (OBlobAndSession.al:120); every value, the full error text and code are dumped in the failure message.
codeunit 98998 "LT WinProbe 63c"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Dump: Text;

    local procedure Obs(Name: Text; Value: Text)
    begin
        Dump += Name + '=' + Value + ' | ';
    end;

    local procedure ObsErr(Name: Text; Ok: Boolean)
    begin
        Obs(Name + ' ok', Format(Ok));
        if not Ok then begin
            Obs(Name + ' error', GetLastErrorText());
            Obs(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [TryFunction]
    local procedure TOpen(var F: File; P: Text)
    begin
        F.Open(P);
    end;

    [TryFunction]
    local procedure TCreate(var F: File; P: Text)
    begin
        F.Create(P);
    end;

    [TryFunction]
    local procedure TryExport(var Row: Record "LT O Blob Row"; Path: Text; var Result: Text)
    begin
        Result := Row.Data.Export(Path);
    end;

    [Test]
    procedure WP63c_File_Create_MissingDir()
    var
        F: File;
        Dir: Text;
    begin
        Dump := '';
        Dir := TemporaryPath() + 'p110nodir' + DelChr(Format(CreateGuid()), '=', '{}-') + '/x.tmp';
        ObsErr('create_in_missing_dir', TCreate(F, Dir));
        ObsErr('open_in_missing_dir', TOpen(F, Dir));
        Obs('exists_in_missing_dir', Format(File.Exists(Dir)));
        if File.Exists(Dir) then
            File.Erase(Dir);
        Error('WP63C DUMP %1', Dump);
    end;

    [Test]
    procedure WP63c_Blob_Export_MissingDir()
    var
        Row: Record "LT O Blob Row";
        Out: OutStream;
        Result: Text;
        Path: Text;
    begin
        Dump := '';
        Row.Data.CreateOutStream(Out);
        Out.WriteText('x');
        Path := TemporaryPath() + 'lt-o-no-such-folder/sub/file.bin';
        ObsErr('export invalid path', TryExport(Row, Path, Result));
        Obs('export result', Result);
        Obs('file exists', Format(File.Exists(Path)));
        Error('WP63C DUMP %1', Dump);
    end;
}
