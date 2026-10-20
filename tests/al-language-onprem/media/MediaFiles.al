// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportfile-method
// Scope: in-scope (OnPrem app: Media.ExportFile / ImportFile and MediaSet.ExportFile / ImportFile are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), table 61294 "PZ OnPrem Media Row" (session/PZMediaImportFile.al) and codeunit 61286
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: Media.ImportFile / ExportFile, MediaSet.ImportFile / ExportFile: returned Guid, Tenant Media properties, exported file, export of an empty media, a missing file
// BC versions: 27, 28, 29
codeunit 61286 "LT S Media Files"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    local procedure TempName(Suffix: Text): Text
    begin
        exit(TemporaryPath() + 'ltsmedia' + DelChr(Format(CreateGuid()), '=', '{}-') + Suffix);
    end;

    local procedure WritePng(Name: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(ValidPngBase64, OutS);
        F.Close();
    end;

    local procedure LenOf(Name: Text): Integer
    var
        F: File;
        L: Integer;
    begin
        F.Open(Name);
        L := F.Len();
        F.Close();
        exit(L);
    end;

    local procedure BaseOf(Name: Text): Text
    begin
        exit(CopyStr(Name, StrLen(TemporaryPath()) + 1));
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure DescribeTenant(Id: Guid; BaseName: Text): Text
    var
        Tenant: Record "Tenant Media";
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        exit('description=[' + Tenant.Description + '] mime=[' + Tenant."Mime Type" + '] filename_contains_source_name=' + Format(StrPos(Tenant."File Name", BaseName) > 0) + ' filename_longer_than_name=' + Format(StrLen(Tenant."File Name") > StrLen(BaseName)) + ' width=' + Format(Tenant.Width) + ' height=' + Format(Tenant.Height) + ' hascontent=' + Format(Tenant.Content.HasValue()));
    end;

    [TryFunction]
    local procedure TryExport(var Row: Record "PZ OnPrem Media Row"; Name: Text)
    begin
        Row.Pic.ExportFile(Name);
    end;

    [TryFunction]
    local procedure TryExportSet(var Row: Record "PZ OnPrem Media Row"; Prefix: Text)
    begin
        Row.Set.ExportFile(Prefix);
    end;

    [TryFunction]
    local procedure TryImport(var Row: Record "PZ OnPrem Media Row"; Name: Text; var Id: Guid)
    begin
        Id := Row.Pic.ImportFile(Name, 'desc');
    end;

    [Test]
    procedure Media_ImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Base64: Codeunit "Base64 Convert";
        Src: Text;
        Dst: Text;
        Id: Guid;
        Id2: Guid;
        InS: InStream;
        F: File;
        Head: Text;
    begin
        Row.SetFilter(Code, 'LTS*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.png');
        Dst := TempName('.png');
        WritePng(Src);
        Row.Code := 'LTSA';
        Id := Row.Pic.ImportFile(Src, 'the description', 'image/png');
        Row.Insert();
        Observer.Observe('import_id_null', Format(IsNullGuid(Id)));
        Observer.Observe('import_id_is_media_id', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant_3args', DescribeTenant(Id, BaseOf(Src)));
        Row.Code := 'LTSB';
        Id2 := Row.Pic.ImportFile(Src, 'second');
        Row.Insert();
        Observer.Observe('tenant_2args', DescribeTenant(Id2, BaseOf(Src)));
        Row.Code := 'LTSC';
        Id2 := Row.Pic.ImportFile(Src, 'third', 'text/plain');
        Row.Insert();
        Observer.Observe('tenant_other_mime', DescribeTenant(Id2, BaseOf(Src)));
        Row.Get('LTSA');
        Observer.Observe('export_return', Format(Row.Pic.ExportFile(Dst)));
        Observer.Observe('source_len', Format(LenOf(Src)));
        Observer.Observe('export_exists', Format(File.Exists(Dst)));
        if File.Exists(Dst) then begin
            Observer.Observe('export_len', Format(LenOf(Dst)));
            F.Open(Dst);
            F.CreateInStream(InS);
            Head := Base64.ToBase64(InS);
            F.Close();
            Observer.Observe('export_base64', Head);
        end;
        Observer.Observe('export_overwrite_ok', Format(TryExport(Row, Dst)));
        Observer.Observe('export_overwrite_len', Format(LenOf(Dst)));
        Cleanup(Src);
        Cleanup(Dst);
        Observer.Expect('import_id_null', 'No');
        Observer.Expect('import_id_is_media_id', 'Yes');
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('tenant_3args', 'description=[the description] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=Yes width=1 height=1 hascontent=Yes');
        Observer.Expect('tenant_2args', 'description=[second] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=Yes width=1 height=1 hascontent=Yes');
        Observer.Expect('tenant_other_mime', 'description=[third] mime=[text/plain] filename_contains_source_name=Yes filename_longer_than_name=Yes width=0 height=0 hascontent=Yes');
        Observer.Expect('export_return', 'Yes');
        Observer.Expect('source_len', '68');
        Observer.Expect('export_exists', 'Yes');
        // Windows re-encodes this 68-byte PNG to 99 bytes: Windows nightly triage 2026-10-16 (codeunit 68571, the same source PNG:
        // 'exported length = 99') and Windows BC 29.0 check 2026-10-20 (29.0 re-encodes a PNG to 99 bytes too, bc-linux #161). The Linux
        // values asserted before (93 on 27/28, 68 on 29) came from the Linux image before bc-linux #135 and #161. The exact Base64 of the
        // re-encoded file is not measured on Windows: not asserted (windows-queue row).
        Observer.Expect('export_len', '99');
        Observer.Ignore('export_base64');
        Observer.Expect('export_overwrite_ok', 'Yes');
        Observer.Expect('export_overwrite_len', '99');
        Observer.Verify();
    end;

    [Test]
    procedure Media_ExportFile_EmptyMedia_AndBadPaths()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Dst: Text;
        Missing: Text;
        Id: Guid;
        Ok: Boolean;
    begin
        Row.SetFilter(Code, 'LTS*');
        Row.DeleteAll();
        Row.Reset();
        Dst := TempName('.png');
        Row.Code := 'LTSE';
        Row.Insert();
        Ok := TryExport(Row, Dst);
        Observer.Observe('empty_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('empty_export_file', Format(File.Exists(Dst)));
        ClearLastError();
        Missing := TemporaryPath() + 'ltsmedia-missing-' + DelChr(Format(CreateGuid()), '=', '{}-') + '.png';
        Ok := TryImport(Row, Missing, Id);
        Observer.Observe('missing_import', Format(Ok) + ' [' + GetLastErrorCode() + ']');
        Observer.Observe('missing_import_text', Format(GetLastErrorText().StartsWith('File ')) + ' ' + Format(GetLastErrorText().EndsWith(' was not found.')) + ' ' + Format(StrPos(GetLastErrorText(), BaseOf(Missing)) > 0));
        ClearLastError();
        Ok := TryImport(Row, '', Id);
        Observer.Observe('empty_import', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExport(Row, '');
        Observer.Observe('empty_name_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExport(Row, '/no/such/dir/out.png');
        Observer.Observe('missing_dir_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExportSet(Row, '/no/such/dir/prefix');
        Observer.Observe('missing_dir_export_set', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TryExportSet(Row, '');
        Observer.Observe('empty_prefix_export_set', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Cleanup(Dst);
        Observer.Expect('empty_export', 'Yes |');
        Observer.Expect('empty_export_file', 'No');
        Observer.Expect('missing_import', 'Yes [FileNotFound]');
        Observer.Expect('missing_import_text', 'Yes Yes Yes');
        Observer.Expect('empty_import', 'No The specified path is invalid.|InvalidPath');
        Observer.Expect('empty_name_export', 'No File name was not specified.|MissingFileName');
        Observer.Expect('missing_dir_export', 'No Could not find a part of the path ''/no/such/dir/out.png''.|InvalidPath');
        Observer.Expect('missing_dir_export_set', 'Yes |');
        Observer.Expect('empty_prefix_export_set', 'No File name was not specified.|MissingFileName');
        Observer.Verify();
    end;

    [Test]
    procedure MediaSet_ImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Src: Text;
        Prefix: Text;
        Dir: Text;
        Id: Guid;
        Id2: Guid;
        Count: Integer;
    begin
        Row.SetFilter(Code, 'LTS*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.png');
        WritePng(Src);
        Row.Code := 'LTSS';
        Id := Row.Set.ImportFile(Src, 'first set item', 'image/png');
        Observer.Observe('set_import_id_null', Format(IsNullGuid(Id)));
        Row.Insert();
        Observer.Observe('set_count_after_one', Format(Row.Set.Count()));
        Id2 := Row.Set.ImportFile(Src, 'second set item');
        Row.Modify();
        Observer.Observe('set_count_after_two', Format(Row.Set.Count()));
        Observer.Observe('set_import_ids_equal', Format(Id = Id2));
        Observer.Observe('set_id_is_media_id', Format(Id2 = Row.Set.MediaId()));
        Observer.Observe('item1', DescribeTenant(Row.Set.Item(1), BaseOf(Src)));
        Observer.Observe('item2', DescribeTenant(Row.Set.Item(2), BaseOf(Src)));
        Row.Get('LTSS');
        Dir := TemporaryPath() + 'ltsmediaset' + DelChr(Format(CreateGuid()), '=', '{}-');
        Prefix := Dir + '-';
        Count := Row.Set.ExportFile(Prefix);
        Observer.Observe('export_count', Format(Count));
        Observer.Observe('prefix_itself_exists', Format(File.Exists(Prefix)));
        Cleanup(Src);
        Observer.Expect('set_import_id_null', 'No');
        Observer.Expect('set_count_after_one', '1');
        Observer.Expect('set_count_after_two', '2');
        Observer.Expect('set_import_ids_equal', 'Yes');
        Observer.Expect('set_id_is_media_id', 'Yes');
        Observer.Expect('item1', 'description=[first set item] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=Yes width=1 height=1 hascontent=Yes');
        Observer.Expect('item2', 'description=[second set item] mime=[image/png] filename_contains_source_name=Yes filename_longer_than_name=Yes width=1 height=1 hascontent=Yes');
        Observer.Expect('export_count', '2');
        Observer.Expect('prefix_itself_exists', 'No');
        Observer.Verify();
    end;
}
