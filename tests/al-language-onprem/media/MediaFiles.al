// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-exportfile-method
// Scope: in-scope (OnPrem app: Media.ExportFile / ImportFile and MediaSet.ExportFile / ImportFile are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), table 61294 "PZ OnPrem Media Row" (session/PZMediaImportFile.al) and codeunit 61286
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: Media.ImportFile / ExportFile, MediaSet.ImportFile / ExportFile: returned Guid, Tenant Media properties, exported file, export of an empty media, a missing file
// Writer QX: a JPEG file through Media.ImportFile and MediaSet.ImportFile with two arguments (Tenant Media row, File Name form).
// Writer RD: a JPEG and an upper-case .PNG into one MediaSet (returned Guid = MediaId, not Item(1)); a .docx into a Media (mime, exported bytes;
//   BC 29 on the Linux tier stores a re-zipped package, not asserted).
// Writer RJ (DemoTool, Export RapidStart Packages: Config. XML Exchange.ExportMediaSet, ConfigXMLExchange.Codeunit.al:1433-1457, then
//   UpdateConfigPackageMediaSet and ImportMediaSetFromFile, :1505-1563): MediaSet.ExportFile(MediaFolder + '\' + Format(Set)) of a set with one
//   and a set with two items, the files File Management.GetServerDirectoryFilesList lists (names, order), their bytes against the imported files.
// BC versions: 27, 28, 29
codeunit 61286 "LT S Media Files"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        RjObserver: Codeunit "Probe Observer";
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

    // ---- Writer QX (Microsoft's DemoTool: Picture.ImportFile(Path + 'cronus.jpg', Desc) on Media and MediaSet fields): a 3 x 2 JPEG file,
    // the Tenant Media row (Mime Type, Description, File Name, Width, Height), HasValue, MediaSet.Count; file name extension .jpg and .JPG. ----

    local procedure QxJpegBase64(): Text
    begin
        exit('/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDABALDA4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/2wBDARESEhgVGC8aGi9jQjhCY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2NjY2Nj' +
            'Y2NjY2NjY2P/wAARCAACAAMDASIAAhEBAxEB/8QAHwAAAQUBAQEBAQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1FhByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVW' +
            'V1hZWmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXGx8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/8QAHwEAAwEBAQEBAQEBAQAAAAAAAAECAwQFBgcICQoL/8QAtREAAgECBAQDBAcFBAQAAQJ3AAEC' +
            'AxEEBSExBhJBUQdhcRMiMoEIFEKRobHBCSMzUvAVYnLRChYkNOEl8RcYGRomJygpKjU2Nzg5OkNERUZHSElKU1RVVldYWVpjZGVmZ2hpanN0dXZ3eHl6goOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4uPk5ebn6Onq' +
            '8vP09fb3+Pn6/9oADAMBAAIRAxEAPwDAooorgPrT/9k=');
    end;

    local procedure QxWriteJpeg(Name: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(QxJpegBase64(), OutS);
        F.Close();
    end;

    local procedure QxFileName(Id: Guid; Src: Text): Text
    var
        Tenant: Record "Tenant Media";
        Name: Text;
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Name := Tenant."File Name";
        Name := Name.Replace(TemporaryPath(), '<tmp>');
        Name := Name.Replace(BaseOf(Src), '<name>');
        exit(Name);
    end;

    [Test]
    procedure QX_MediaAndMediaSet_ImportFile_Jpeg()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Src: Text;
        SrcUpper: Text;
        Id: Guid;
    begin
        Row.SetFilter(Code, 'LTQX*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.jpg');
        SrcUpper := TempName('.JPG');
        QxWriteJpeg(Src);
        QxWriteJpeg(SrcUpper);
        Observer.Observe('file length', Format(LenOf(Src)));
        Row.Code := 'LTQXA';
        Id := Row.Pic.ImportFile(Src, 'Cronus picture');
        Row.Insert();
        Observer.Observe('media hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('media tenant', DescribeTenant(Id, BaseOf(Src)));
        Observer.Observe('media file name', QxFileName(Id, Src));
        Row.Code := 'LTQXB';
        Id := Row.Pic.ImportFile(SrcUpper, 'Upper case extension');
        Row.Insert();
        Observer.Observe('media upper tenant', DescribeTenant(Id, BaseOf(SrcUpper)));
        Row.Code := 'LTQXC';
        Clear(Row.Pic);
        Id := Row.Set.ImportFile(Src, 'Item picture');
        Row.Insert();
        Observer.Observe('mediaset count', Format(Row.Set.Count()));
        Observer.Observe('mediaset item 1 tenant', DescribeTenant(Row.Set.Item(1), BaseOf(Src)));
        Observer.Observe('mediaset file name', QxFileName(Row.Set.Item(1), Src));
        Row.Get('LTQXC');
        Observer.Observe('mediaset count after get', Format(Row.Set.Count()));
        Row.SetFilter(Code, 'LTQX*');
        Row.DeleteAll();
        Cleanup(Src);
        Cleanup(SrcUpper);
        Observer.Expect('file length', '632');
        Observer.Expect('media hasvalue', 'Yes');
        Observer.Expect('media tenant', 'description=[Cronus picture] mime=[image/jpeg] filename_contains_source_name=Yes filename_longer_than_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('media file name', '<tmp><name>');
        Observer.Expect('media upper tenant', 'description=[Upper case extension] mime=[image/jpeg] filename_contains_source_name=Yes filename_longer_than_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('mediaset count', '1');
        Observer.Expect('mediaset item 1 tenant', 'description=[Item picture] mime=[image/jpeg] filename_contains_source_name=Yes filename_longer_than_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Ignore('mediaset file name');
        Observer.Expect('mediaset count after get', '1');
        Observer.Verify();
    end;

    // ---- Writer RD (Microsoft's DemoTool, round 2: Item.Picture.ImportFile(Path, "No.") into a MediaSet with the result unused,
    // Sales Document Icon SetIconFromFile of 'SalesStatusIcons\Quote.PNG' into a MediaSet, Word Template.Template.ImportFile(Path, 'Template')
    // of a .docx into a Media): a JPEG and then a 2 x 3 PNG with an upper-case .PNG extension into the same MediaSet (the returned Guid against
    // MediaId and Item(1), the order of the items, Mime Type, Width, Height); a .docx file into a Media (Tenant Media row, File Name form,
    // the exported bytes). The Tenant Media File Name of a MediaSet item differs between the Linux and the Windows service tier (windows-check QX
    // item 9) and is not asserted here. ----

    local procedure RdPngBase64(): Text
    begin
        exit('iVBORw0KGgoAAAANSUhEUgAAAAIAAAADCAIAAAA2iEnWAAAAEElEQVR42mP4zwAE/xlQKAA+1gX7ttb52gAAAABJRU5ErkJggg==');
    end;

    local procedure RdDocxBase64(): Text
    begin
        exit('UEsDBBQAAAAIAAAAIVx5bjPX6AAAAK0BAAATAAAAW0NvbnRlbnRfVHlwZXNdLnhtbH1QyU7DMBD9FWuuKHHggBCK0wPLETiUDxjZk8SqN3nc0v49Tlt6QIXjzFv1+tXeO7GjzDYGBbdt' +
            'B4KCjsaGScHn+rV5AMEFg0EXAyk4EMNq6NeHRCyqNrCCuZT0KCXrmTxyGxOFiowxeyz1zJNMqDc4kbzrunupYygUSlMWDxj6Zxpx64p42df3qUcmxyCeTsQlSwGm5KzGUnG5C+ZXSnNO' +
            'aKvyyOHZJr6pBJBXExbk74Cz7r0Ok60h8YG5vKGvLPkVs5Em6q2vyvZ/mys94zhaTRf94pZy1MRcF/euvSAebfjpL49zD99QSwMEFAAAAAgAAAAhXJv9N+qtAAAAKQEAAAsAAABfcmVs' +
            'cy8ucmVsc43POw7CMAwG4KtE3mlaBoRQ0y4IqSsqB7ASN61oHkrCo7cnAwNFDIy2f3+W6/ZpZnanECdnBVRFCYysdGqyWsClP232wGJCq3B2lgQsFKFt6jPNmPJKHCcfWTZsFDCm5A+c' +
            'RzmSwVg4TzZPBhcMplwGzT3KK2ri27Lc8fBpwNpknRIQOlUB6xdP/9huGCZJRydvhmz6ceIrkWUMmpKAhwuKq3e7yCzwpuarF5sXUEsDBBQAAAAIAAAAIVzXDGLpogAAANcAAAARAAAA' +
            'd29yZC9kb2N1bWVudC54bWxFjkEOwiAQRa9C2FuqC2Oa0m6MK1emHgBhbJvADAG09vZCXbh5PzOT/zJt/3GWvSHEmVDyfVVzBqjJzDhKfh8uuxNnMSk0yhKC5CtE3nft0hjSLweYWBZg' +
            'bBbJp5R8I0TUEzgVK/KA+fak4FTKYxjFQsH4QBpizH5nxaGuj8KpGXlRPsisJX1BKEjddWC3M0vgvFUJWlF2hWGj3/jrif9P3RdQSwECFAMUAAAACAAAACFceW4z1+gAAACtAQAAEwAA' +
            'AAAAAAAAAAAAgAEAAAAAW0NvbnRlbnRfVHlwZXNdLnhtbFBLAQIUAxQAAAAIAAAAIVyb/TfqrQAAACkBAAALAAAAAAAAAAAAAACAARkBAABfcmVscy8ucmVsc1BLAQIUAxQAAAAIAAAA' +
            'IVzXDGLpogAAANcAAAARAAAAAAAAAAAAAACAAe8BAAB3b3JkL2RvY3VtZW50LnhtbFBLBQYAAAAAAwADALkAAADAAgAAAAA=');
    end;

    local procedure RdWriteBase64(Name: Text; Base64Text: Text)
    var
        F: File;
        OutS: OutStream;
        Base64: Codeunit "Base64 Convert";
    begin
        F.Create(Name);
        F.CreateOutStream(OutS);
        Base64.FromBase64(Base64Text, OutS);
        F.Close();
    end;

    local procedure RdTenant(Id: Guid; BaseName: Text): Text
    var
        Tenant: Record "Tenant Media";
    begin
        if not Tenant.Get(Id) then
            exit('no tenant media row');
        Tenant.CalcFields(Content);
        exit('description=[' + Tenant.Description + '] mime=[' + Tenant."Mime Type" + '] filename_contains_source_name=' + Format(StrPos(Tenant."File Name", BaseName) > 0) + ' width=' + Format(Tenant.Width) + ' height=' + Format(Tenant.Height) + ' hascontent=' + Format(Tenant.Content.HasValue()));
    end;

    [Test]
    procedure RD_MediaSet_ImportFile_JpegThenUpperCasePng()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Jpg: Text;
        Png: Text;
        Id1: Guid;
        Id2: Guid;
        IdPic: Guid;
    begin
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Row.Reset();
        Jpg := TempName('.jpg');
        Png := TempName('.PNG');
        QxWriteJpeg(Jpg);
        RdWriteBase64(Png, RdPngBase64());
        Observer.Observe('png file length', Format(LenOf(Png)));
        Row.Code := 'LTRDA';
        Id1 := Row.Set.ImportFile(Jpg, 'jpeg item');
        Row.Insert();
        Id2 := Row.Set.ImportFile(Png, 'png item');
        Row.Modify();
        Observer.Observe('count', Format(Row.Set.Count()));
        Observer.Observe('returned ids equal', Format(Id1 = Id2));
        Observer.Observe('returned id is MediaId', Format(Id1 = Row.Set.MediaId()));
        Observer.Observe('returned id is Item(1)', Format(Id1 = Row.Set.Item(1)));
        Observer.Observe('returned id is Item(2)', Format(Id1 = Row.Set.Item(2)));
        Observer.Observe('Item(1) is Item(2)', Format(Row.Set.Item(1) = Row.Set.Item(2)));
        Observer.Observe('format returned id length', Format(StrLen(Format(Id1))));
        Observer.Observe('format Item(1) length', Format(StrLen(Format(Row.Set.Item(1)))));
        Observer.Observe('item 1', RdTenant(Row.Set.Item(1), BaseOf(Jpg)));
        Observer.Observe('item 2', RdTenant(Row.Set.Item(2), BaseOf(Png)));
        Row.Get('LTRDA');
        Observer.Observe('count after get', Format(Row.Set.Count()));
        Observer.Observe('item 1 after get', RdTenant(Row.Set.Item(1), BaseOf(Jpg)));
        Observer.Observe('item 2 after get', RdTenant(Row.Set.Item(2), BaseOf(Png)));
        Row.Code := 'LTRDB';
        IdPic := Row.Pic.ImportFile(Png, 'png media');
        Row.Insert();
        Observer.Observe('media png returned id is MediaId', Format(IdPic = Row.Pic.MediaId()));
        Observer.Observe('media png', RdTenant(IdPic, BaseOf(Png)));
        Row.Reset();
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Cleanup(Jpg);
        Cleanup(Png);
        Observer.Expect('png file length', '73');
        Observer.Expect('count', '2');
        Observer.Expect('returned ids equal', 'Yes');
        Observer.Expect('returned id is MediaId', 'Yes');
        Observer.Expect('returned id is Item(1)', 'No');
        Observer.Expect('returned id is Item(2)', 'No');
        Observer.Expect('Item(1) is Item(2)', 'No');
        Observer.Expect('format returned id length', '38');
        Observer.Expect('format Item(1) length', '38');
        Observer.Expect('item 1', 'description=[jpeg item] mime=[image/jpeg] filename_contains_source_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('item 2', 'description=[png item] mime=[image/png] filename_contains_source_name=Yes width=2 height=3 hascontent=Yes');
        Observer.Expect('count after get', '2');
        Observer.Expect('item 1 after get', 'description=[jpeg item] mime=[image/jpeg] filename_contains_source_name=Yes width=3 height=2 hascontent=Yes');
        Observer.Expect('item 2 after get', 'description=[png item] mime=[image/png] filename_contains_source_name=Yes width=2 height=3 hascontent=Yes');
        Observer.Expect('media png returned id is MediaId', 'Yes');
        Observer.Expect('media png', 'description=[png media] mime=[image/png] filename_contains_source_name=Yes width=2 height=3 hascontent=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RD_Media_ImportFile_Docx()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "PZ OnPrem Media Row";
        Tenant: Record "Tenant Media";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
        Src: Text;
        Id: Guid;
    begin
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Row.Reset();
        Src := TempName('.docx');
        RdWriteBase64(Src, RdDocxBase64());
        Observer.Observe('file length', Format(LenOf(Src)));
        Row.Code := 'LTRDD';
        Id := Row.Pic.ImportFile(Src, 'Template');
        Row.Insert();
        Observer.Observe('returned id is MediaId', Format(Id = Row.Pic.MediaId()));
        Observer.Observe('hasvalue', Format(Row.Pic.HasValue()));
        Observer.Observe('tenant', RdTenant(Id, BaseOf(Src)));
        Observer.Observe('file name', QxFileName(Id, Src));
        if Tenant.Get(Id) then begin
            Tenant.CalcFields(Content);
            Tenant.Content.CreateInStream(InS);
            Observer.Observe('tenant content is the file', Format(Base64.ToBase64(InS) = RdDocxBase64()));
        end;
        Row.Get('LTRDD');
        TempBlob.CreateOutStream(OutS);
        Row.Pic.ExportStream(OutS);
        Observer.Observe('export length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        Observer.Observe('export is the file', Format(Base64.ToBase64(InS) = RdDocxBase64()));
        Row.Reset();
        Row.SetFilter(Code, 'LTRD*');
        Row.DeleteAll();
        Cleanup(Src);
        Observer.Expect('file length', '911');
        Observer.Expect('returned id is MediaId', 'Yes');
        Observer.Expect('hasvalue', 'Yes');
        Observer.Expect('tenant', 'description=[Template] mime=[application/vnd.openxmlformats-officedocument.wordprocessingml.document] filename_contains_source_name=Yes width=0 height=0 hascontent=Yes');
        Observer.Expect('file name', '<tmp><name>');
#if BC29PLUS
        // BC 29 on the Linux CI tier stores a re-zipped package (same parts, other compressed bytes: 919 bytes); queued for the Windows check.
        Observer.Ignore('tenant content is the file');
        Observer.Ignore('export length');
        Observer.Ignore('export is the file');
#else
        Observer.Expect('tenant content is the file', 'Yes');
        Observer.Expect('export length', '911');
        Observer.Expect('export is the file', 'Yes');
#endif
        Observer.Verify();
    end;

    // ---- Writer RJ (Microsoft's DemoTool, Export RapidStart Packages: Config. XML Exchange.ExportMediaSet copies the field through a FieldRef
    // into a temporary Config. Media Buffer and calls "Media Set".ExportFile(MediaFolder + '\' + Format("Media Set")), MediaFolder being
    // CombinePath(<package folder>, 'Media'); UpdateConfigPackageMediaSet lists that folder with GetServerDirectoryFilesList and reads each file
    // back with BLOBImportFromServerFile, Media Set ID = GetFileNameWithoutExtension(file name)). Names are masked: <dir> is the package
    // folder, <set1>/<set2> the Format of the sets, <s2i1> etc. the Format of an item's media id (also without braces and in lower case). ----

    local procedure RjMask(Value: Text; Id: Guid; Tag: Text): Text
    var
        G: Text;
    begin
        G := Format(Id);
        Value := Value.Replace(G, '<' + Tag + '>');
        Value := Value.Replace(LowerCase(G), '<' + Tag + '>');
        G := DelChr(G, '=', '{}');
        Value := Value.Replace(G, '<' + Tag + '-nobraces>');
        Value := Value.Replace(LowerCase(G), '<' + Tag + '-nobraces-lower>');
        exit(Value);
    end;

    local procedure RjMaskAll(Value: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"): Text
    begin
        Value := Value.Replace(Dir, '<dir>');
        Value := RjMask(Value, Row1.Set.MediaId(), 'set1');
        Value := RjMask(Value, Row2.Set.MediaId(), 'set2');
        Value := RjMask(Value, Row1.Set.Item(1), 's1i1');
        Value := RjMask(Value, Row2.Set.Item(1), 's2i1');
        Value := RjMask(Value, Row2.Set.Item(2), 's2i2');
        exit(Value);
    end;

    local procedure RjTenantBase64(Id: Guid): Text
    var
        Tenant: Record "Tenant Media";
        Base64: Codeunit "Base64 Convert";
        InS: InStream;
    begin
        if not Tenant.Get(Id) then
            exit('');
        Tenant.CalcFields(Content);
        Tenant.Content.CreateInStream(InS);
        exit(Base64.ToBase64(InS));
    end;

    local procedure RjExportSet(var Row: Record "PZ OnPrem Media Row"; MediaFolder: Text): Integer
    var
        TempConfigMediaBuffer: Record "Config. Media Buffer" temporary;
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(Row);
        FieldRef := RecRef.Field(Row.FieldNo(Set));
        TempConfigMediaBuffer.Init();
        TempConfigMediaBuffer."Media Set" := FieldRef.Value();
        TempConfigMediaBuffer.Insert();
        exit(TempConfigMediaBuffer."Media Set".ExportFile(MediaFolder + '\' + Format(TempConfigMediaBuffer."Media Set")));
    end;

    local procedure RjListFolder(Folder: Text; Recursive: Boolean; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"; JpgB64: Text; PngB64: Text): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        FileManagement: Codeunit "File Management";
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        DummyGuid: Guid;
        InS: InStream;
        B64: Text;
        Same: Text;
        Result: Text;
    begin
        if Recursive then
            FileManagement.GetServerDirectoryFilesListInclSubDirs(TempNameValueBuffer, Folder)
        else
            FileManagement.GetServerDirectoryFilesList(TempNameValueBuffer, Folder);
        if Folder = TemporaryPath() then begin
            // only the entries this test wrote (names that hold a set or item id or the package folder)
            if TempNameValueBuffer.FindSet() then
                repeat
                    if (StrPos(RjMaskAll(TempNameValueBuffer.Name, Dir, Row1, Row2), '<s') = 0) and (StrPos(TempNameValueBuffer.Name, 'ltrjpkg') = 0) then
                        TempNameValueBuffer.Delete();
                until TempNameValueBuffer.Next() = 0;
        end;
        Result := Format(TempNameValueBuffer.Count()) + ':';
        if TempNameValueBuffer.FindSet() then
            repeat
                Clear(TempBlob);
                FileManagement.BLOBImportFromServerFile(TempBlob, TempNameValueBuffer.Name);
                TempBlob.CreateInStream(InS);
                B64 := Base64.ToBase64(InS);
                Same := '';
                if B64 = JpgB64 then
                    Same += ' jpg';
                if B64 = PngB64 then
                    Same += ' png';
                if B64 = RjTenantBase64(Row1.Set.Item(1)) then
                    Same += ' s1i1';
                if B64 = RjTenantBase64(Row2.Set.Item(1)) then
                    Same += ' s2i1';
                if B64 = RjTenantBase64(Row2.Set.Item(2)) then
                    Same += ' s2i2';
                Result += '[' + Format(TempNameValueBuffer.ID) + '|' + RjMaskAll(TempNameValueBuffer.Name, Dir, Row1, Row2) + '|v=' +
                  RjMaskAll(TempNameValueBuffer.Value, Dir, Row1, Row2) + '|id=' +
                  RjMaskAll(CopyStr(FileManagement.GetFileNameWithoutExtension(TempNameValueBuffer.Name), 1, StrLen(Format(DummyGuid))), Dir, Row1, Row2) +
                  '|len=' + Format(TempBlob.Length()) + '|bytes of:' + Same + ']';
            until TempNameValueBuffer.Next() = 0;
        exit(Result);
    end;

    // Which of the likely names (prefix + separator + index + extension) AL File.Exists finds after an export, with the file length.
    local procedure RjCandidates(Prefix: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row"): Text
    var
        F: File;
        Seps: List of [Text];
        Exts: List of [Text];
        Sep: Text;
        Ext: Text;
        Name: Text;
        Result: Text;
        i: Integer;
    begin
        Seps.Add('');
        Seps.Add('-');
        Seps.Add('_');
        Seps.Add(' ');
        Seps.Add('.');
        Seps.Add('/');
        Exts.Add('');
        Exts.Add('.jpg');
        Exts.Add('.jpeg');
        Exts.Add('.png');
        Exts.Add('.JPG');
        Exts.Add('.PNG');
        Exts.Add('.bin');
        for i := 0 to 3 do
            foreach Sep in Seps do
                foreach Ext in Exts do begin
                    Name := Prefix + Sep + Format(i) + Ext;
                    if File.Exists(Name) then begin
                        F.Open(Name);
                        Result += '[' + RjMaskAll(Name, Dir, Row1, Row2) + '|len=' + Format(F.Len()) + ']';
                        F.Close();
                    end;
                end;
        foreach Ext in Exts do
            if File.Exists(Prefix + Ext) then
                Result += '[' + RjMaskAll(Prefix + Ext, Dir, Row1, Row2) + ']';
        for i := 1 to Row2.Set.Count() do
            foreach Sep in Seps do
                foreach Ext in Exts do begin
                    Name := Prefix + Sep + Format(Row2.Set.Item(i)) + Ext;
                    if File.Exists(Name) then
                        Result += '[' + RjMaskAll(Name, Dir, Row1, Row2) + ']';
                    Name := Prefix + Sep + DelChr(Format(Row2.Set.Item(i)), '=', '{}') + Ext;
                    if File.Exists(Name) then
                        Result += '[' + RjMaskAll(Name, Dir, Row1, Row2) + ']';
                end;
        exit(Result);
    end;

    [TryFunction]
    local procedure RjTryList(var Result: Text; Folder: Text; Dir: Text; var Row1: Record "PZ OnPrem Media Row"; var Row2: Record "PZ OnPrem Media Row")
    begin
        Result := RjListFolder(Folder, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64());
    end;

    [Test]
    procedure RJ_MediaSet_ExportFile_ConfigPackageShape()
    var
        Row1: Record "PZ OnPrem Media Row";
        Row2: Record "PZ OnPrem Media Row";
        FileManagement: Codeunit "File Management";
        Jpg: Text;
        Png: Text;
        Dir: Text;
        MediaFolder: Text;
        Count1: Integer;
        Count2: Integer;
        TempList: Text;
    begin
        Row1.SetFilter(Code, 'LTRJ*');
        Row1.DeleteAll();
        Row1.Reset();
        Jpg := TempName('.jpg');
        Png := TempName('.png');
        QxWriteJpeg(Jpg);
        RdWriteBase64(Png, RdPngBase64());
        Dir := TemporaryPath() + 'ltrjpkg' + DelChr(Format(CreateGuid()), '=', '{}-');
        FileManagement.ServerCreateDirectory(Dir);
        MediaFolder := FileManagement.CombinePath(Dir, 'Media');
        FileManagement.ServerCreateDirectory(MediaFolder);
        RjObserver.Observe('media folder', MediaFolder.Replace(Dir, '<dir>'));
        Row1.Code := 'LTRJ1';
        Row1.Set.ImportFile(Png, 'png item');
        Row1.Insert();
        Row2.Code := 'LTRJ2';
        Row2.Set.ImportFile(Jpg, 'jpeg item');
        Row2.Insert();
        Row2.Set.ImportFile(Png, 'png item');
        Row2.Modify();
        Row1.Get('LTRJ1');
        Row2.Get('LTRJ2');
        RjObserver.Observe('set counts', Format(Row1.Set.Count()) + '|' + Format(Row2.Set.Count()));
        RjObserver.Observe('format set length', Format(StrLen(Format(Row1.Set))));
        RjObserver.Observe('format set is MediaId', Format(Format(Row1.Set) = Format(Row1.Set.MediaId())));
        RjObserver.Observe('tenant item bytes same as files', Format(RjTenantBase64(Row1.Set.Item(1)) = RdPngBase64()) + '|' +
          Format(RjTenantBase64(Row2.Set.Item(1)) = QxJpegBase64()) + '|' + Format(RjTenantBase64(Row2.Set.Item(2)) = RdPngBase64()));
        Count1 := RjExportSet(Row1, MediaFolder);
        RjObserver.Observe('export count one item', Format(Count1));
        RjObserver.Observe('media folder after one', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('package folder after one, with sub folders', RjListFolder(Dir, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        Count2 := RjExportSet(Row2, MediaFolder);
        RjObserver.Observe('export count two items', Format(Count2));
        RjObserver.Observe('media folder after two', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('al file names after two', RjCandidates(MediaFolder + '\' + Format(Row2.Set), Dir, Row1, Row2));
        RjObserver.Observe('package folder after two, with sub folders', RjListFolder(Dir, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        Count1 := RjExportSet(Row1, MediaFolder);
        RjObserver.Observe('export count one item again', Format(Count1));
        RjObserver.Observe('media folder after again', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        if RjTryList(TempList, TemporaryPath(), Dir, Row1, Row2) then
            RjObserver.Observe('temporary path, with sub folders', TempList)
        else
            RjObserver.Observe('temporary path, with sub folders', 'error ' + GetLastErrorText());
        // the same with a prefix that has no backslash: CombinePath(MediaFolder, Format(Set))
        Count2 := Row2.Set.ExportFile(FileManagement.CombinePath(MediaFolder, Format(Row2.Set)));
        RjObserver.Observe('slash prefix export count', Format(Count2));
        RjObserver.Observe('slash prefix al file names', RjCandidates(FileManagement.CombinePath(MediaFolder, Format(Row2.Set)), Dir, Row1, Row2));
        RjObserver.Observe('slash prefix media folder', RjListFolder(MediaFolder, false, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        RjObserver.Observe('slash prefix package folder, with sub folders', RjListFolder(Dir, true, Dir, Row1, Row2, QxJpegBase64(), RdPngBase64()));
        FileManagement.ServerRemoveDirectory(Dir, true);
        Row1.Reset();
        Row1.SetFilter(Code, 'LTRJ*');
        Row1.DeleteAll();
        Cleanup(Jpg);
        Cleanup(Png);
        RjObserver.Finish();
    end;

    [Test]
    procedure RJ_MediaSet_ExportFile_ConfigPackageShape_More1()
    begin
        RjObserver.More();
    end;

    [Test]
    procedure RJ_MediaSet_ExportFile_ConfigPackageShape_More2()
    begin
        RjObserver.More();
    end;
}
