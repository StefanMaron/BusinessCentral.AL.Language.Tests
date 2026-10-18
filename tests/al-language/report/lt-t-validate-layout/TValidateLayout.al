// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-validateandpreparelayout-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application), layout file ./FixtureLayout.rdlc of the app root; self-contained report 69367, test codeunit 69366
// Facts: Report.ValidateAndPrepareLayout, static (report id) and on a Report variable: the return value, the prepared stream and the error for the report's own layout and for text that is not a layout,
// for each layout type, and the error of an unknown report id when the Ok result is not used.
// BC versions: 27.0 and later

report 69367 "LT T Layout Rpt"
{
    UseRequestPage = false;
    DefaultRenderingLayout = TRdlc;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(TRdlc)
        {
            Type = RDLC;
            LayoutFile = './FixtureLayout.rdlc';
        }
    }
}

codeunit 69366 "LT T Validate Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ReadAll(var Content: InStream): Text
    var
        Line: Text;
        Result: Text;
    begin
        while not Content.EOS() do begin
            Content.ReadText(Line);
            Result += Line + '\n';
        end;
        exit(Result);
    end;

    local procedure TextStream(Content: Text; var TempBlob: Codeunit "Temp Blob"; var Stream: InStream)
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(Content);
        TempBlob.CreateInStream(Stream);
    end;

    local procedure OwnLayout(var Stream: InStream)
    begin
        Report.RdlcLayout(Report::"LT T Layout Rpt", Stream);
    end;

    local procedure Describe(Tag: Text; Ok: Boolean; var Prepared: InStream; Original: Text)
    var
        Text1: Text;
    begin
        Observer.Observe(Tag + ' ok', Format(Ok));
        Observer.Observe(Tag + ' error', GetLastErrorText());
        if Prepared.EOS() then
            Observer.Observe(Tag + ' prepared', 'EOS')
        else begin
            Text1 := ReadAll(Prepared);
            Observer.Observe(Tag + ' prepared length', Format(StrLen(Text1)));
            Observer.Observe(Tag + ' prepared equals original', Format(Text1 = Original));
        end;
        ClearLastError();
    end;

    [Test]
    procedure Validate_Static_OwnRdlcLayout()
    var
        Layout: InStream;
        Again: InStream;
        Prepared: InStream;
        Original: Text;
        Ok: Boolean;
    begin
        OwnLayout(Again);
        Original := ReadAll(Again);
        Observer.Observe('original length', Format(StrLen(Original)));
        OwnLayout(Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::RDLC);
        Describe('static rdlc', Ok, Prepared, Original);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Static_NotALayout()
    var
        TempBlob: Codeunit "Temp Blob";
        Layout: InStream;
        Prepared: InStream;
        Ok: Boolean;
    begin
        TextStream('this is not a layout', TempBlob, Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::RDLC);
        Describe('static rdlc garbage', Ok, Prepared, '');
        Clear(TempBlob);
        Clear(Prepared);
        TextStream('this is not a layout', TempBlob, Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::Word);
        Describe('static word garbage', Ok, Prepared, '');
        Clear(TempBlob);
        Clear(Prepared);
        TextStream('this is not a layout', TempBlob, Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::Excel);
        Describe('static excel garbage', Ok, Prepared, '');
        Clear(TempBlob);
        Clear(Prepared);
        TextStream('', TempBlob, Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::RDLC);
        Describe('static rdlc empty', Ok, Prepared, '');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Static_RdlcLayoutAsWord()
    var
        Layout: InStream;
        Prepared: InStream;
        Ok: Boolean;
    begin
        OwnLayout(Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::Word);
        Describe('static rdlc content as word', Ok, Prepared, '');
        Clear(Prepared);
        OwnLayout(Layout);
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::Excel);
        Describe('static rdlc content as excel', Ok, Prepared, '');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Static_NoOkResult_Errors()
    var
        TempBlob: Codeunit "Temp Blob";
        Layout: InStream;
        Prepared: InStream;
    begin
        TextStream('this is not a layout', TempBlob, Layout);
        asserterror Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::RDLC);
        Observer.ObserveError('static garbage');
        asserterror Report.ValidateAndPrepareLayout(71999, Layout, Prepared, ReportLayoutType::RDLC);
        Observer.ObserveError('static unknown report');
        asserterror Report.ValidateAndPrepareLayout(0, Layout, Prepared, ReportLayoutType::RDLC);
        Observer.ObserveError('static report 0');
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Instance_OwnRdlcLayout()
    var
        Rpt: Report "LT T Layout Rpt";
        Layout: InStream;
        Again: InStream;
        Prepared: InStream;
        Original: Text;
        Ok: Boolean;
    begin
        OwnLayout(Again);
        Original := ReadAll(Again);
        OwnLayout(Layout);
        Ok := Rpt.ValidateAndPrepareLayout(Layout, Prepared, ReportLayoutType::RDLC);
        Describe('instance rdlc', Ok, Prepared, Original);
        Observer.Finish();
    end;

    [Test]
    procedure Validate_Instance_NotALayout()
    var
        Rpt: Report "LT T Layout Rpt";
        TempBlob: Codeunit "Temp Blob";
        Layout: InStream;
        Prepared: InStream;
        Ok: Boolean;
    begin
        TextStream('this is not a layout', TempBlob, Layout);
        Ok := Rpt.ValidateAndPrepareLayout(Layout, Prepared, ReportLayoutType::RDLC);
        Describe('instance rdlc garbage', Ok, Prepared, '');
        Clear(TempBlob);
        Clear(Prepared);
        TextStream('this is not a layout', TempBlob, Layout);
        Ok := Rpt.ValidateAndPrepareLayout(Layout, Prepared, ReportLayoutType::Word);
        Describe('instance word garbage', Ok, Prepared, '');
        Clear(TempBlob);
        Clear(Prepared);
        TextStream('this is not a layout', TempBlob, Layout);
        asserterror Rpt.ValidateAndPrepareLayout(Layout, Prepared, ReportLayoutType::RDLC);
        Observer.ObserveError('instance garbage no result');
        Observer.Finish();
    end;
}
