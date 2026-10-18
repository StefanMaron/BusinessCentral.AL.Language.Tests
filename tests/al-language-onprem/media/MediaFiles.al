// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportfile-method
// Scope: in-scope (OnPrem app: Media.ExportFile / ImportFile and MediaSet.ExportFile / ImportFile are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 61284 and codeunit 61285
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: Media.ImportFile / ExportFile, MediaSet.ImportFile / ExportFile: returned Guid, Tenant Media properties, exported file, export of an empty media, a missing file
// BC versions: 27, 28, 29
table 61284 "LT S Media File Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Pic; Media) { }
        field(3; Pics; MediaSet) { }
    }

    keys { key(PK; Code) { Clustered = true; } }
}

codeunit 61285 "LT S Media Files"
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

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    local procedure DescribeTenant(Id: Guid): Text
    var
        Tenant: Record "Tenant Media";
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        exit('description=[' + Tenant.Description + '] mime=[' + Tenant."Mime Type" + '] filename=[' + Tenant."File Name" + '] width=' + Format(Tenant.Width) + ' height=' + Format(Tenant.Height) + ' hascontent=' + Format(Tenant.Content.HasValue()));
    end;

    [TryFunction]
    local procedure TryExport(var Row: Record "LT S Media File Row"; Name: Text)
    begin
        Row.Pic.ExportFile(Name);
    end;

    [TryFunction]
    local procedure TryExportSet(var Row: Record "LT S Media File Row"; Prefix: Text)
    begin
        Row.Pics.ExportFile(Prefix);
    end;

    [TryFunction]
    local procedure TryImport(var Row: Record "LT S Media File Row"; Name: Text; var Id: Guid)
    begin
        Id := Row.Pic.ImportFile(Name, 'desc');
    end;

    [Test]
    procedure Media_ImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Media File Row";
        Base64: Codeunit "Base64 Convert";
        Src: Text;
        Dst: Text;
        Id: Guid;
        Id2: Guid;
        InS: InStream;
        F: File;
        Head: Text;
    begin
        Row.DeleteAll();
        Src := TempName('.png');
        Dst := TempName('.png');
        WritePng(Src);
        Row.Code := 'A';
        Id := Row.Pic.ImportFile(Src, 'the description', 'image/png');
        Row.Insert();
        Observer.Observe('import_id_null', Format(IsNullGuid(Id)));
        Observer.Observe('import_id_is_media_id', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant_3args', DescribeTenant(Id));
        Row.Code := 'B';
        Id2 := Row.Pic.ImportFile(Src, 'second');
        Row.Insert();
        Observer.Observe('tenant_2args', DescribeTenant(Id2));
        Row.Code := 'C';
        Id2 := Row.Pic.ImportFile(Src, 'third', 'text/plain');
        Row.Insert();
        Observer.Observe('tenant_other_mime', DescribeTenant(Id2));
        Row.Get('A');
        Observer.Observe('export_return', Format(Row.Pic.ExportFile(Dst)));
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
        Observer.Finish();
    end;

    [Test]
    procedure Media_ExportFile_EmptyMedia_AndBadPaths()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Media File Row";
        Dst: Text;
        Id: Guid;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Dst := TempName('.png');
        Row.Code := 'E';
        Row.Insert();
        Ok := TryExport(Row, Dst);
        Observer.Observe('empty_export', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe('empty_export_file', Format(File.Exists(Dst)));
        ClearLastError();
        Ok := TryImport(Row, TemporaryPath() + 'ltsmedia-missing-' + DelChr(Format(CreateGuid()), '=', '{}-') + '.png', Id);
        Observer.Observe('missing_import', Format(Ok) + ' [' + GetLastErrorCode() + ']');
        Observer.Observe('missing_import_text_head', CopyStr(GetLastErrorText(), 1, 40));
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
        Observer.Finish();
    end;

    [Test]
    procedure MediaSet_ImportFile_ExportFile()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT S Media File Row";
        Names: Record "Name/Value Buffer" temporary;
        FileMgt: Codeunit "File Management";
        Src: Text;
        Prefix: Text;
        Dir: Text;
        Id: Guid;
        Id2: Guid;
        Count: Integer;
    begin
        Row.DeleteAll();
        Src := TempName('.png');
        WritePng(Src);
        Row.Code := 'S';
        Id := Row.Pics.ImportFile(Src, 'first set item', 'image/png');
        Observer.Observe('set_import_id_null', Format(IsNullGuid(Id)));
        Row.Insert();
        Observer.Observe('set_count_after_one', Format(Row.Pics.Count()));
        Id2 := Row.Pics.ImportFile(Src, 'second set item');
        Row.Modify();
        Observer.Observe('set_count_after_two', Format(Row.Pics.Count()));
        Observer.Observe('set_import_ids_equal', Format(Id = Id2));
        Observer.Observe('set_id_is_media_id', Format(Id2 = Row.Pics.MediaId()));
        Observer.Observe('item1', DescribeTenant(Row.Pics.Item(1)));
        Observer.Observe('item2', DescribeTenant(Row.Pics.Item(2)));
        Row.Get('S');
        Dir := TemporaryPath() + 'ltsmediaset' + DelChr(Format(CreateGuid()), '=', '{}-');
        Prefix := Dir + '-';
        Count := Row.Pics.ExportFile(Prefix);
        Observer.Observe('export_count', Format(Count));
        FileMgt.GetServerDirectoryFilesList(Names, TemporaryPath());
        Names.SetFilter(Value, StrSubstNo('%1*', Prefix));
        Observer.Observe('exported_files', Format(Names.Count()));
        if Names.FindSet() then
            repeat
                Observer.Observe('exported_name_' + Format(Names.ID), CopyStr(Names.Value, StrLen(Prefix) + 1));
                File.Erase(Names.Value);
            until Names.Next() = 0;
        Cleanup(Src);
        Observer.Finish();
    end;
}
