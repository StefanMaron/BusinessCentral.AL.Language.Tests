// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/blob/blob-export-method
// Scope: in-scope (OnPrem app only: Blob.Export, Blob.Import, SecretText.Unwrap, SessionInformation.AITokensUsed, Session.LogSecurityAudit)
// Fixtures used: Probe Observer (69160) and table "LT O Blob Row" (67220), from the AL Language Coverage Tests app; codeunits 61236 and 61257
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Blob.Export(file) return value, file content (read back with Blob.Import) and the error for an invalid path;
// Blob.Import(file) length and content, and the error for a missing file; SecretText.Unwrap of a filled and an empty SecretText;
// SessionInformation.AITokensUsed at session start; Session.LogSecurityAudit with and without the optional target arrays.
// BC versions: 27, 28, 29
codeunit 61236 "LT O Blob File"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryExport(var Row: Record "LT O Blob Row"; Path: Text; var Result: Text)
    begin
        Result := Row.Data.Export(Path);
    end;

    [TryFunction]
    local procedure TryImport(var Row: Record "LT O Blob Row"; Path: Text; var Result: Text)
    begin
        Result := Row.Data.Import(Path);
    end;

    [Test]
    procedure O_Blob_ExportImport_RoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT O Blob Row";
        Back: Record "LT O Blob Row";
        Out: OutStream;
        Inn: InStream;
        Path: Text;
        Result: Text;
        Content: Text;
    begin
        Path := TemporaryPath() + 'lt-o-blob-roundtrip.bin';
        Row.Data.CreateOutStream(Out);
        Out.WriteText('blob content 123');
        if TryExport(Row, Path, Result) then
            Observer.Observe('export', 'return=' + Result)
        else
            Observer.ObserveError('export');
        if TryImport(Back, Path, Result) then
            Observer.Observe('import', 'return=' + Result)
        else
            Observer.ObserveError('import');
        Observer.Observe('imported length', Format(Back.Data.Length()));
        Back.Data.CreateInStream(Inn);
        Inn.ReadText(Content);
        Observer.Observe('imported content', Content);
        if Erase(Path) then;
        Observer.Finish();
    end;

    [Test]
    procedure O_Blob_Export_InvalidPath_Import_MissingFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT O Blob Row";
        Out: OutStream;
        Result: Text;
    begin
        Row.Data.CreateOutStream(Out);
        Out.WriteText('x');
        if TryExport(Row, TemporaryPath() + 'lt-o-no-such-folder/sub/file.bin', Result) then
            Observer.Observe('export invalid path', 'return=' + Result)
        else
            Observer.ObserveError('export invalid path');
        if TryImport(Row, TemporaryPath() + 'lt-o-missing-file.bin', Result) then
            Observer.Observe('import missing', 'return=' + Result)
        else
            Observer.ObserveError('import missing');
        Observer.Observe('blob length after failed import', Format(Row.Data.Length()));
        if TryExport(Row, '', Result) then
            Observer.Observe('export blank', 'return=' + Result)
        else
            Observer.ObserveError('export blank');
        Observer.Finish();
    end;
}

codeunit 61257 "LT O Session Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAudit(WithTargets: Boolean)
    var
        Sources: array[2] of Text;
    begin
        if WithTargets then begin
            Sources[1] := 'a';
            Sources[2] := 'b';
            Session.LogSecurityAudit('LT O audit', SecurityOperationResult::Success, 'LT O detail', AuditCategory::ApplicationManagement);
        end else
            Session.LogSecurityAudit('LT O audit', SecurityOperationResult::Failure, 'LT O detail', AuditCategory::Authentication);
    end;

    [Test]
    procedure O_Session_LogSecurityAudit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if TryAudit(false) then
            Observer.Observe('plain', 'no error')
        else
            Observer.ObserveError('plain');
        if TryAudit(true) then
            Observer.Observe('second form', 'no error')
        else
            Observer.ObserveError('second form');
        Observer.Finish();
    end;

    [Test]
    procedure O_SessionInformation_AITokensUsed()
    var
        Observer: Codeunit "Probe Observer";
        Used: Variant;
        Count: Integer;
    begin
        Count := SessionInformation.AITokensUsed();
        Used := SessionInformation.AITokensUsed();
        Observer.Observe('value', Format(Count));
        Observer.Observe('is integer', Format(Used.IsInteger()));
        Observer.Finish();
    end;

    [Test]
    procedure O_SecretText_Unwrap()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Empty: SecretText;
    begin
        Secret := SecretStrSubstNo('abcdef');
        Observer.Observe('filled', Secret.Unwrap());
        Observer.Observe('empty', '[' + Empty.Unwrap() + ']');
        Observer.Observe('empty is empty', Format(Empty.IsEmpty()));
        Observer.Finish();
    end;
}
