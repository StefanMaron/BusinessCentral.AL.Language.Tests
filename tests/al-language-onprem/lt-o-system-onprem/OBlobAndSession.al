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
            Observer.Observe('export', 'return ends with file name=' + Format(Result.EndsWith('lt-o-blob-roundtrip.bin')))
        else
            Observer.ObserveError('export');
        if TryImport(Back, Path, Result) then
            Observer.Observe('import', 'return ends with file name=' + Format(Result.EndsWith('lt-o-blob-roundtrip.bin')))
        else
            Observer.ObserveError('import');
        Observer.Observe('imported length', Format(Back.Data.Length()));
        Back.Data.CreateInStream(Inn);
        Inn.ReadText(Content);
        Observer.Observe('imported content', Content);
        if Erase(Path) then;
        Observer.Expect('export', 'return ends with file name=Yes');
        Observer.Expect('import', 'return ends with file name=Yes');
        Observer.Expect('imported length', '16');
        Observer.Expect('imported content', 'blob content 123');
        Observer.Verify();
    end;

    // The error text holds the service tier's temporary folder: observe its start and end only.
    local procedure ObservePathError(var Observer: Codeunit "Probe Observer"; Tag: Text)
    var
        Text: Text;
    begin
        Text := GetLastErrorText();
        Observer.Observe(Tag + '|starts', CopyStr(Text, 1, 5));
        Observer.Observe(Tag + '|ends', CopyStr(Text, StrLen(Text) - 18, 19));
        Observer.Observe(Tag + '|code', GetLastErrorCode());
        ClearLastError();
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
            Observer.Observe('export invalid path', 'return ends with file name=' + Format(Result.EndsWith('file.bin')))
        else
            Observer.ObserveError('export invalid path');
        if TryImport(Row, TemporaryPath() + 'lt-o-missing-file.bin', Result) then
            Observer.Observe('import missing', 'return=' + Result)
        else
            ObservePathError(Observer, 'import missing');
        Observer.Observe('blob length after failed import', Format(Row.Data.Length()));
        if TryExport(Row, '', Result) then
            Observer.Observe('export blank', 'return=' + Result)
        else
            Observer.ObserveError('export blank');
        Observer.Expect('export invalid path', 'return ends with file name=Yes');
        Observer.Expect('import missing|starts', 'File ');
        Observer.Expect('import missing|ends', '.bin was not found.');
        Observer.Expect('import missing|code', 'FileNotFound');
        Observer.Expect('blob length after failed import', '1');
        Observer.Expect('export blank|text', 'File name was not specified.');
        Observer.Expect('export blank|code', 'MissingFileName');
        Observer.Verify();
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
        Observer.Expect('plain', 'no error');
        Observer.Expect('second form', 'no error');
        Observer.Verify();
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
        Observer.Observe('is decimal', Format(Used.IsDecimal()));
        Observer.Observe('is biginteger', Format(Used.IsBigInteger()));
        Observer.Expect('value', '0');
        Observer.Expect('is integer', 'No');
        Observer.Expect('is decimal', 'No');
        Observer.Expect('is biginteger', 'Yes');
        Observer.Verify();
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
        Observer.Expect('filled', 'abcdef');
        Observer.Expect('empty', '[]');
        Observer.Expect('empty is empty', 'Yes');
        Observer.Verify();
    end;

    // corpus issue 669 (writer CO): LogSecurityAudit with target type and target name arrays of equal length. Arrays of different lengths
    // (2 types, 1 name) ended the local Linux BC 29 session ("hub connection closed"): a Linux suspect, queued for Windows, not asserted here.
    [TryFunction]
    local procedure TryAuditTargets(TypeCount: Integer; NameCount: Integer)
    var
        Types2: array[2] of Text;
        Types1: array[1] of Text;
        Names2: array[2] of Text;
        Names1: array[1] of Text;
    begin
        Types2[1] := 'Table';
        Types2[2] := 'Page';
        Types1[1] := 'Table';
        Names2[1] := 'Customer';
        Names2[2] := 'Customer Card';
        Names1[1] := 'Customer';
        if (TypeCount = 2) and (NameCount = 1) then
            Session.LogSecurityAudit('LT CO audit', SecurityOperationResult::Success, 'LT CO detail', AuditCategory::ApplicationManagement, Types2, Names1);
        if (TypeCount = 1) and (NameCount = 2) then
            Session.LogSecurityAudit('LT CO audit', SecurityOperationResult::Success, 'LT CO detail', AuditCategory::ApplicationManagement, Types1, Names2);
        if (TypeCount = 2) and (NameCount = 2) then
            Session.LogSecurityAudit('LT CO audit', SecurityOperationResult::Success, 'LT CO detail', AuditCategory::ApplicationManagement, Types2, Names2);
        if (TypeCount = 1) and (NameCount = 1) then
            Session.LogSecurityAudit('LT CO audit', SecurityOperationResult::Failure, 'LT CO detail', AuditCategory::UserManagement, Types1, Names1);
    end;

    local procedure AuditTargetsOutcome(TypeCount: Integer; NameCount: Integer): Text
    begin
        ClearLastError();
        if TryAuditTargets(TypeCount, NameCount) then
            exit('no error');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    [Test]
    procedure O_Session_LogSecurityAudit_TargetArrayLengths_CO()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('two types, two names', AuditTargetsOutcome(2, 2));
        Observer.Observe('one type, one name', AuditTargetsOutcome(1, 1));
        Observer.Finish();
    end;
}
