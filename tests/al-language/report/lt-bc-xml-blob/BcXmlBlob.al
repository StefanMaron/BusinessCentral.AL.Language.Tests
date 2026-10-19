// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in BcXmlBlobObjects.al
// Corpus issue 659 item 4 (from al-runtime-rs #253): Report.SaveAs with ReportFormat::Xml succeeds for a dataset with a Blob column.
// These tests read the XML text written for Blob, Media and MediaSet columns, empty and with content.

codeunit 80979 "BC Xml Blob"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dataset(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        All: Text;
        Lf: Text[1];
        At: Integer;
    begin
        Lf[1] := 10;
        TempBlob.CreateOutStream(OutS);
        ClearLastError();
        if not Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS) then
            exit('not saved: ' + GetLastErrorText());
        if not TempBlob.HasValue() then
            exit('empty');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line + Lf;
        end;
        At := All.IndexOf('<DataItems>');
        if At = 0 then
            exit('no DataItems: ' + All);
        exit(All.Substring(At));
    end;

    [TryFunction]
    local procedure TryImport(var Row: Record "BC Blob Row"; InS: InStream)
    begin
        Row.Pic.ImportStream(InS, 'bc probe');
    end;

    local procedure Setup()
    var
        Row: Record "BC Blob Row";
        OutS: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Note := 'empty';
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Note := 'text';
        Row.Data.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('Hello BC');
        Row.Insert();
    end;

    [Test]
    procedure Xml_BlobMediaColumns_EmptyAndText()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
    begin
        Setup();
        Observer.Observe('dataset', Dataset(Report::"BC Xml Blob Columns"));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure Xml_BlobColumn_CalcFieldsInTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
    begin
        Setup();
        Observer.Observe('dataset', Dataset(Report::"BC Xml Blob CalcFields"));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure Xml_BlobColumn_BinaryBytes()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
        OutS: OutStream;
        B: Byte;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 3;
        Row.Note := 'bytes';
        Row.Data.CreateOutStream(OutS);
        B := 0;
        OutS.Write(B);
        B := 255;
        OutS.Write(B);
        B := 65;
        OutS.Write(B);
        Row.Insert();
        Observer.Observe('dataset', Dataset(Report::"BC Xml Blob CalcFields"));
        Row.DeleteAll();
        Observer.Finish();
    end;

    [Test]
    procedure Xml_CompanyPicture_Repro()
    var
        Observer: Codeunit "Probe Observer";
        Company: Record "Company Information";
        Text: Text;
    begin
        // The repro of al-runtime-rs #253: the dataset is written; the picture column depends on the company's picture, so only its shape is asserted.
        Company.Get();
        Company.CalcFields(Picture);
        Observer.Observe('company has picture', Format(Company.Picture.HasValue()));
        Text := Dataset(Report::"BC Xml Company Picture");
        Observer.Observe('saved', Format(Text.StartsWith('<DataItems>')));
        Observer.Observe('has picture column', Format(Text.Contains('CompanyPicture')));
        Observer.Observe('dataset', Text);
        Observer.Finish();
    end;

    [Test]
    procedure Xml_MediaColumns_WithContent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "BC Blob Row";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Text: Text;
        MediaId: Guid;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 4;
        Row.Note := 'media';
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('not an image');
        TempBlob.CreateInStream(InS);
        ClearLastError();
        if TryImport(Row, InS) then;
        Observer.Observe('import error', GetLastErrorText());
        MediaId := Row.Pic.MediaId();
        Observer.Observe('media has value', Format(Row.Pic.HasValue()));
        Row.Insert();
        Text := Dataset(Report::"BC Xml Blob Columns");
        if not IsNullGuid(MediaId) then begin
            Text := Text.Replace(Format(MediaId), '<media-id>');
            Text := Text.Replace(DelChr(Format(MediaId), '=', '{}'), '<media-id-bare>');
            Text := Text.Replace(LowerCase(DelChr(Format(MediaId), '=', '{}')), '<media-id-lower>');
        end;
        Observer.Observe('dataset', Text);
        Row.DeleteAll();
        Observer.Finish();
    end;
}
