// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-saveascsv-method
// Scope: in-scope (OnPrem app: the file forms of Query.SaveAsCsv and Query.SaveAsXml are Scope = OnPrem)
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 61287
// Probe: written against BC 29 (runtime 16); the values are measured on the corpus CI service tiers.
// Facts: Query.SaveAsCsv and Query.SaveAsXml into a file, as instance and by object number: return value, file text, Format and FormatArgument, errors
// BC versions: 27, 28, 29
codeunit 61287 "LT S Query SaveAs File"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P160 QRow";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'a,b;c "q" <x>';
        Row.Amt := 12.5;
        Row.D := DMY2Date(5, 3, 2024);
        Row.Flag := true;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Name := '';
        Row.Amt := 0;
        Row.Insert();
    end;

    local procedure TempName(Suffix: Text): Text
    begin
        exit(TemporaryPath() + 'ltsqfile' + DelChr(Format(CreateGuid()), '=', '{}-') + Suffix);
    end;

    local procedure ObserveFile(var Observer: Codeunit "Probe Observer"; Name: Text; Tag: Text; FromMarker: Text)
    var
        F: File;
        InS: InStream;
        Raw: Text;
        Len: Integer;
        B: Byte;
        First3: Text;
        i: Integer;
    begin
        Observer.Observe(Tag + ' exists', Format(File.Exists(Name)));
        if not File.Exists(Name) then
            exit;
        F.Open(Name);
        Len := F.Len();
        Observer.Observe(Tag + ' length', Format(Len));
        F.CreateInStream(InS);
        for i := 1 to 3 do
            if not InS.EOS() then begin
                InS.Read(B);
                First3 += Format(B) + ' ';
            end;
        Observer.Observe(Tag + ' first bytes', First3);
        F.Close();
        F.Open(Name);
        F.CreateInStream(InS);
        if Len > 0 then
            InS.Read(Raw, Len);
        F.Close();
        i := 1;
        if FromMarker <> '' then
            i := StrPos(Raw, FromMarker);
        if i = 0 then
            i := 1;
        Observer.Observe(Tag + ' text', CopyStr(Raw, i, 700));
        File.Erase(Name);
    end;

    [Test]
    procedure SaveAsCsv_File_Instance()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QSave";
        Name: Text;
        Ok: Boolean;
    begin
        Seed();
        Name := TempName('.csv');
        Observer.Observe('default ok', Format(Q.SaveAsCsv(Name)));
        ObserveFile(Observer, Name, 'default', '');
        Ok := TrySaveCsvFormat(Name, 0);
        Observer.Observe('format0', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        ObserveFile(Observer, Name, 'format0', '');
        Ok := TrySaveCsvFormat(Name, 3);
        Observer.Observe('format3', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        ObserveFile(Observer, Name, 'format3', '');
        Observer.Observe('format1 semicolon ok', Format(Q.SaveAsCsv(Name, 1, ';')));
        ObserveFile(Observer, Name, 'format1 semicolon', '');
        Observer.Observe('format2 ok', Format(Q.SaveAsCsv(Name, 2, '')));
        ObserveFile(Observer, Name, 'format2', '');
        Q.SetFilter(Id, '2');
        Observer.Observe('filtered ok', Format(Q.SaveAsCsv(Name)));
        ObserveFile(Observer, Name, 'filtered', '');
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsCsv_File_ByNumber()
    var
        Observer: Codeunit "Probe Observer";
        Name: Text;
    begin
        Seed();
        Name := TempName('.csv');
        Observer.Observe('default ok', Format(Query.SaveAsCsv(71922, Name)));
        ObserveFile(Observer, Name, 'default', '');
        Observer.Observe('format1 semicolon ok', Format(Query.SaveAsCsv(71922, Name, 1, ';')));
        ObserveFile(Observer, Name, 'format1 semicolon', '');
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_File_Instance_AndByNumber()
    var
        Observer: Codeunit "Probe Observer";
        Q: Query "LT P160 QSave";
        Name: Text;
    begin
        Seed();
        Name := TempName('.xml');
        Observer.Observe('instance ok', Format(Q.SaveAsXml(Name)));
        ObserveFile(Observer, Name, 'instance', '<Result>');
        Observer.Observe('by number ok', Format(Query.SaveAsXml(71922, Name)));
        ObserveFile(Observer, Name, 'by number', '<Result>');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TrySaveCsvFormat(Name: Text; FormatKind: Integer)
    var
        Q: Query "LT P160 QSave";
    begin
        Q.SaveAsCsv(Name, FormatKind, '');
    end;

    [TryFunction]
    local procedure TrySaveCsv(Name: Text)
    var
        Q: Query "LT P160 QSave";
    begin
        Q.SaveAsCsv(Name);
    end;

    [TryFunction]
    local procedure TrySaveXml(Name: Text)
    var
        Q: Query "LT P160 QSave";
    begin
        Q.SaveAsXml(Name);
    end;

    [TryFunction]
    local procedure TrySaveByNumber(Number: Integer; Name: Text)
    begin
        Query.SaveAsCsv(Number, Name);
    end;

    [Test]
    procedure SaveAs_File_BadPaths()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Seed();
        Ok := TrySaveCsv('');
        Observer.Observe('csv empty name', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveCsv('/no/such/dir/out.csv');
        Observer.Observe('csv missing dir', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveXml('');
        Observer.Observe('xml empty name', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveXml('/no/such/dir/out.xml');
        Observer.Observe('xml missing dir', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Ok := TrySaveByNumber(61299, TempName('.csv'));
        Observer.Observe('unknown query number', Format(Ok) + ' ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        Observer.Finish();
    end;
}
