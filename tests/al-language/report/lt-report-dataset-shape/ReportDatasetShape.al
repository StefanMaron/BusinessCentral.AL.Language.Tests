// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); own table 71932, reports 71933 and 71934
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: ReportName and ReportCaption of a report with and without a Caption property; the lines after the header of a dataset with no rows; the spelling of empty and zero column values (Text, Integer, Date, Boolean, Decimal, Time, Option) of one row.
// BC versions: 29 (27 and 28 by CI)

table 71932 "LT P160 DsRow"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amt; Decimal) { }
        field(4; D; Date) { }
        field(5; Flag; Boolean) { }
        field(6; T; Time) { }
        field(7; Opt; Option)
        {
            OptionMembers = First,Second;
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 71933 "LT P160 Rep Plain"
{
    dataset
    {
        dataitem(Rows; "LT P160 DsRow")
        {
            column(RowId; Id) { }
            column(RowName; Name) { }
            column(RowAmt; Amt) { }
            column(RowD; D) { }
            column(RowFlag; Flag) { }
            column(RowT; T) { }
            column(RowOpt; Opt) { }
        }
    }
}

report 71934 "LT P160 Rep Captioned"
{
    Caption = 'LT P160 Own Caption';

    dataset
    {
        dataitem(Rows; "LT P160 DsRow")
        {
            column(RowId; Id) { }
        }
    }
}

codeunit 71935 "LT P160 Dataset Shape"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Lines: List of [Text];

    local procedure Load(var TempBlob: Codeunit "Temp Blob")
    var
        InS: InStream;
        Line: Text;
    begin
        Clear(Lines);
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Lines.Add(Line);
        end;
    end;

    local procedure CountContaining(Part: Text): Integer
    var
        L: Text;
        N: Integer;
    begin
        foreach L in Lines do
            if StrPos(L, Part) > 0 then
                N += 1;
        exit(N);
    end;

    local procedure FirstContaining(Part: Text): Text
    var
        L: Text;
    begin
        foreach L in Lines do
            if StrPos(L, Part) > 0 then
                exit(L);
        exit('none');
    end;

    local procedure Seed(WithRow: Boolean)
    var
        Row: Record "LT P160 DsRow";
    begin
        Row.DeleteAll();
        if WithRow then begin
            Row.Init();
            Row.Id := 0;
            Row.Insert();
        end;
    end;

#if BC29PLUS
    [Test]
    procedure Header_ReportCaption_WithoutCaptionProperty()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT P160 Rep Plain";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed(true);
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rep.SaveAs('', ReportFormat::Xml, OutS)));
        Load(TempBlob);
        Observer.Observe('ReportName line', FirstContaining('<ReportName>'));
        Observer.Observe('ReportCaption line', FirstContaining('<ReportCaption>'));
        Observer.Observe('ReportCaption count', Format(CountContaining('ReportCaption')));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ReportName line', '      <ReportName>LT P160 Rep Plain</ReportName>');
        Observer.Expect('ReportCaption line', '      <ReportCaption>LT P160 Rep Plain</ReportCaption>');
        Observer.Expect('ReportCaption count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Header_ReportCaption_WithCaptionProperty()
    var
        Observer: Codeunit "Probe Observer";
        Rep: Report "LT P160 Rep Captioned";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Seed(true);
        TempBlob.CreateOutStream(OutS);
        Observer.Observe('saved', Format(Rep.SaveAs('', ReportFormat::Xml, OutS)));
        Load(TempBlob);
        Observer.Observe('ReportName line', FirstContaining('<ReportName>'));
        Observer.Observe('ReportCaption line', FirstContaining('<ReportCaption>'));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('ReportName line', '      <ReportName>LT P160 Rep Captioned</ReportName>');
        Observer.Expect('ReportCaption line', '      <ReportCaption>LT P160 Own Caption</ReportCaption>');
        Observer.Verify();
    end;
#endif
}
