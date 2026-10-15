// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), PnBObjects.al (report 70530, tables 70527/70528, log 70531), self-contained codeunit 70535
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
//   "Report.SaveAs dataset | Only `ReportFormat::Xml` is produced..." (line 120),
//   "Report.SaveAs dataset | The header: ..." (121), "Rows: a row is written after OnAfterGetRecord..." (122),
//   "Names: a data item or column named with letters..." (123), "Report.SaveAs run | No request page opens..." (124),
//   "Report | UseTemporary = true on a data item..." (125)
// BC versions: 29 (27 and 28 by CI)

codeunit 70535 "LT PnB SaveAs Xml"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LogCu: Codeunit "LT PnB Log 1";
        Lines: List of [Text];
        RawText: Text;

    local procedure Seed()
    var
        Row: Record "LT PnB Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Amount := 10.5;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Name := 'Two';
        Row.Insert();
        Row.Init();
        Row.Id := 3;
        Row.Name := 'Three';
        Row.Insert();
        Row.Init();
        Row.Id := 11;
        Row."Parent Id" := 1;
        Row.Name := 'Kid';
        Row.Insert();
    end;

    local procedure Render(var Rep: Report "LT PnB Rep"; Params: Text; Fmt: ReportFormat): Boolean
    var
        Blob: Record "LT PnB Blob";
        OS: OutStream;
        IS: InStream;
        Line: Text;
        Ok: Boolean;
        Len: Integer;
    begin
        Blob.DeleteAll();
        Blob.Id := 1;
        Blob.Insert();
        Blob.Data.CreateOutStream(OS);
        Ok := Rep.SaveAs(Params, Fmt, OS);
        Blob.Modify();
        Clear(Lines);
        RawText := '';
        Blob.CalcFields(Data);
        Len := Blob.Data.Length();
        if Len > 0 then begin
            Blob.Data.CreateInStream(IS);
            IS.Read(RawText, Len);
            Blob.Data.CreateInStream(IS, TextEncoding::UTF8);
            while not IS.EOS() do begin
                IS.ReadText(Line);
                Lines.Add(StripSystemId(Line));
            end;
        end;
        exit(Ok);
    end;

    local procedure StripSystemId(Line: Text): Text
    var
        P: Integer;
        Q: Integer;
        Rest: Text;
    begin
        P := StrPos(Line, ' systemId="');
        if P = 0 then
            exit(Line);
        Rest := CopyStr(Line, P + 11);
        Q := StrPos(Rest, '"');
        exit(CopyStr(Line, 1, P - 1) + CopyStr(Rest, Q + 1));
    end;

    local procedure CountContaining(Part: Text): Integer
    var
        L: Text;
        N: Integer;
    begin
        foreach L in Lines do begin
            if StrPos(L, Part) > 0 then
                N += 1;
        end;
        exit(N);
    end;

    [Test]
    procedure Header_RawBytes()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        i: Integer;
        Lf: Integer;
        Cr: Integer;
        Code: Integer;
    begin
        Seed();
        Obs.Observe('ok', Format(Render(Rep, '', ReportFormat::Xml)));
        Obs.Observe('totalLen>0', Format(StrLen(RawText) > 0));
        for i := 1 to 3 do begin
            Code := RawText[i];
            Obs.Observe('byte' + Format(i), Format(Code));
        end;
        for i := 1 to StrLen(RawText) do begin
            Code := RawText[i];
            if Code = 10 then
                Lf += 1;
            if Code = 13 then
                Cr += 1;
        end;
        Obs.Observe('lfCount', Format(Lf));
        Obs.Observe('crCount', Format(Cr));
        Obs.Observe('lines', Format(Lines.Count()));
        Obs.Expect('ok', 'Yes');
        Obs.Expect('totalLen>0', 'Yes');
        Obs.Expect('byte1', '239');
        Obs.Expect('byte2', '187');
        Obs.Expect('byte3', '191');
        Obs.Expect('lfCount', '112');
        Obs.Expect('crCount', '0');
        Obs.Expect('lines', '113');
        Obs.Verify();
    end;

    [Test]
    procedure Header_Lines()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        i: Integer;
    begin
        Seed();
        Render(Rep, '', ReportFormat::Xml);
        for i := 1 to 22 do begin
            if i <= Lines.Count() then
                Obs.Observe('line' + Format(i), Lines.Get(i));
        end;
        Obs.Observe('lines', Format(Lines.Count()));
        Obs.Expect('line1', '<?xml version="1.0" standalone="yes"?>');
        Obs.Expect('line2', '<ReportDataSet name="LT PnB Rep" id="70530" language="en-US" formatRegion="en-US">');
        Obs.Expect('line4', '    <ReportMetadata>');
        Obs.Expect('line5', '      <ExtensionId>a1b2c3d4-e5f6-7890-abcd-ef1234567890</ExtensionId>');
        Obs.Expect('line6', '      <ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>');
        Obs.Expect('line7', '      <ExtensionPublisher>AL Language</ExtensionPublisher>');
        Obs.Expect('line8', '      <ExtensionVersion>x</ExtensionVersion>');
        Obs.Expect('line9', '      <ReportId>70530</ReportId>');
        Obs.Expect('line10', '      <ReportName>LT PnB Rep</ReportName>');
        Obs.Expect('line11', '      <ReportCaption>LT PnB Caption</ReportCaption>');
        Obs.Expect('line12', '      <AboutThisReportTitle></AboutThisReportTitle>');
        Obs.Expect('line13', '      <AboutThisReportText></AboutThisReportText>');
        Obs.Expect('line14', '      <ReportHelpLink></ReportHelpLink>');
        Obs.Expect('line15', '    </ReportMetadata>');
        Obs.Expect('line16', '    <ReportRequest>');
        Obs.Expect('line17', '      <TenantEntraId>x</TenantEntraId>');
        Obs.Expect('line18', '      <EnvironmentName>x</EnvironmentName>');
        Obs.Expect('line19', '      <EnvironmentType>x</EnvironmentType>');
        Obs.Expect('line20', '      <CompanyName>x</CompanyName>');
        Obs.Expect('line21', '      <CompanyDisplayName>x</CompanyDisplayName>');
        Obs.Expect('line22', '      <CompanyId>x</CompanyId>');
        Obs.Expect('lines', '113');
        Obs.Ignore('line3'); // a dump or environment data: observed, not asserted
        Obs.Verify();
    end;

    [Test]
    procedure Rows_BlockAfterHeader()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        i: Integer;
        Start: Integer;
        Seen: Integer;
    begin
        Seed();
        Render(Rep, '', ReportFormat::Xml);
        for i := 1 to Lines.Count() do begin
            if (Start = 0) and (StrPos(Lines.Get(i), 'DataItems') > 0) then
                Start := i;
        end;
        Obs.Observe('dataItemsLine>0', Format(Start > 0));
        for i := Start to Lines.Count() do begin
            if Seen < 24 then begin
                Seen += 1;
                Obs.Observe('r' + Format(Seen), Lines.Get(i));
            end;
        end;
        Obs.Expect('dataItemsLine>0', 'Yes');
        Obs.Expect('r1', '  <DataItems>');
        Obs.Expect('r2', '    <DataItem language="en-US" formatRegion="en-US" name="Rows" tableId="70527">');
        Obs.Expect('r3', '      <Columns>');
        Obs.Expect('r4', '        <Column name="RowId">1</Column>');
        Obs.Expect('r5', '        <Column name="RowName">One</Column>');
        Obs.Expect('r6', '        <Column name="RowAmount" decimalformatter="#,##0.00">10.5</Column>');
        Obs.Expect('r7', '        <Column name="RowTag">T1</Column>');
        Obs.Expect('r8', '        <Column name="ColSpaced">1</Column>');
        Obs.Expect('r9', '      </Columns>');
        Obs.Expect('r10', '      <DataItems>');
        Obs.Expect('r11', '        <DataItem name="Kid_Item_Table" tableId="70527">');
        Obs.Expect('r12', '          <Columns>');
        Obs.Expect('r13', '            <Column name="KidId">11</Column>');
        Obs.Expect('r14', '          </Columns>');
        Obs.Expect('r15', '        </DataItem>');
        Obs.Expect('r16', '      </DataItems>');
        Obs.Expect('r17', '    </DataItem>');
        Obs.Expect('r18', '    <DataItem language="en-US" formatRegion="en-US" name="Rows" tableId="70527">');
        Obs.Expect('r19', '      <Columns>');
        Obs.Expect('r20', '        <Column name="RowId">2</Column>');
        Obs.Expect('r21', '        <Column name="RowName">Two</Column>');
        Obs.Expect('r22', '        <Column name="RowAmount" decimalformatter="#,##0.00">0</Column>');
        Obs.Expect('r23', '        <Column name="RowTag">T2</Column>');
        Obs.Expect('r24', '        <Column name="ColSpaced">2</Column>');
        Obs.Verify();
    end;

    [Test]
    procedure Rows_SkipAndBreak()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        Rep2: Report "LT PnB Rep";
    begin
        Seed();
        LogCu.Reset();
        Rep.SetSkip(2);
        Render(Rep, '', ReportFormat::Xml);
        Obs.Observe('skip.rowIdLines', Format(CountContaining('<RowId>')));
        Obs.Observe('skip.hasTwo', Format(CountContaining('<RowName>Two</RowName>')));
        Obs.Observe('skip.kidLines', Format(CountContaining('KidId')));
        Obs.Observe('skip.log', LogCu.Joined());
        LogCu.Reset();
        Rep2.SetBreak(2);
        Render(Rep2, '', ReportFormat::Xml);
        Obs.Observe('break.rowIdLines', Format(CountContaining('<RowId>')));
        Obs.Observe('break.hasOne', Format(CountContaining('<RowName>One</RowName>')));
        Obs.Observe('break.hasTwo', Format(CountContaining('<RowName>Two</RowName>')));
        Obs.Observe('break.log', LogCu.Joined());
        Obs.Expect('skip.rowIdLines', '0');
        Obs.Expect('skip.hasTwo', '0');
        Obs.Expect('skip.kidLines', '1');
        Obs.Expect('skip.log', 'OnInitReport,RP.OnInit,OnPreReport:,Row1,Row3,OnPostReport');
        Obs.Expect('break.rowIdLines', '0');
        Obs.Expect('break.hasOne', '0');
        Obs.Expect('break.hasTwo', '0');
        Obs.Expect('break.log', 'OnInitReport,RP.OnInit,OnPreReport:,Row1,OnPostReport');
        Obs.Verify();
    end;

    [Test]
    procedure Rows_ColumnBoundToVariable()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
    begin
        Seed();
        Render(Rep, '', ReportFormat::Xml);
        Obs.Observe('tag1', Format(CountContaining('<RowTag>T1</RowTag>')));
        Obs.Observe('tag3', Format(CountContaining('<RowTag>T3</RowTag>')));
        Obs.Observe('amountLine', Format(CountContaining('<RowAmount>10.5</RowAmount>')));
        Obs.Observe('emptyAmount', Format(CountContaining('<RowAmount>0</RowAmount>')));
        Obs.Observe('tagCount', Format(CountContaining('<RowTag>')));
        Obs.Expect('tag1', '0');
        Obs.Expect('tag3', '0');
        Obs.Expect('amountLine', '0');
        Obs.Expect('emptyAmount', '0');
        Obs.Expect('tagCount', '0');
        Obs.Verify();
    end;

    [Test]
    procedure Names_SpacesAndParentheses()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        L: Text;
        N: Integer;
    begin
        Seed();
        Render(Rep, '', ReportFormat::Xml);
        foreach L in Lines do begin
            if (StrPos(L, 'Kid') > 0) or (StrPos(L, 'Col_') > 0) or (StrPos(L, 'Spaced') > 0) then
                if N < 20 then begin
                    N += 1;
                    Obs.Observe('n' + Format(N), L);
                end;
        end;
        Obs.Expect('n1', '        <Column name="ColSpaced">1</Column>');
        Obs.Expect('n2', '        <DataItem name="Kid_Item_Table" tableId="70527">');
        Obs.Expect('n3', '            <Column name="KidId">11</Column>');
        Obs.Expect('n4', '        <Column name="ColSpaced">2</Column>');
        Obs.Expect('n5', '        <Column name="ColSpaced">3</Column>');
        Obs.Verify();
    end;

    [Test]
    procedure TemporaryDataItem()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
    begin
        Seed();
        Render(Rep, '', ReportFormat::Xml);
        Obs.Observe('tempInfo', Rep.GetTempInfo());
        Obs.Observe('tmpIdLines', Format(CountContaining('TmpId')));
        Obs.Observe('tmpIdValueLines', Format(CountContaining('<TmpId>')));
        Obs.Expect('tempInfo', 'Yes/0');
        Obs.Expect('tmpIdLines', '0');
        Obs.Expect('tmpIdValueLines', '0');
        Obs.Verify();
    end;

    [Test]
    procedure TriggerOrder()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
    begin
        Seed();
        LogCu.Reset();
        Rep.SetPrefix('pf');
        Obs.Observe('ok', Format(Render(Rep, '', ReportFormat::Xml)));
        Obs.Observe('log', LogCu.Joined());
        Obs.Observe('prefixAfter', Rep.GetPrefix());
        Obs.Expect('ok', 'Yes');
        Obs.Expect('log', 'OnInitReport,RP.OnInit,OnPreReport:pf,Row1,Row2,Row3,OnPostReport');
        Obs.Expect('prefixAfter', 'pf');
        Obs.Verify();
    end;

    [Test]
    procedure OtherFormats_NoLayout()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        Ok: Boolean;
    begin
        Seed();
        Ok := Render(Rep, '', ReportFormat::Html);
        Obs.Observe('html.ok', Format(Ok));
        Obs.Observe('html.err', GetLastErrorText());
        Obs.Observe('html.len>0', Format(StrLen(RawText) > 0));
        ClearLastError();
        Ok := Render(Rep, '', ReportFormat::Pdf);
        Obs.Observe('pdf.ok', Format(Ok));
        Obs.Observe('pdf.err', GetLastErrorText());
        ClearLastError();
        Ok := Render(Rep, '', ReportFormat::Word);
        Obs.Observe('word.ok', Format(Ok));
        Obs.Observe('word.err', GetLastErrorText());
        ClearLastError();
        Ok := Render(Rep, '', ReportFormat::Excel);
        Obs.Observe('excel.ok', Format(Ok));
        Obs.Observe('excel.err', GetLastErrorText());
        ClearLastError();
        Obs.Observe('xmlOrdinal', Format(ReportFormat::Xml, 0, 2));
        Obs.Observe('pdfOrdinal', Format(ReportFormat::Pdf, 0, 2));
        Obs.Observe('wordOrdinal', Format(ReportFormat::Word, 0, 2));
        Obs.Observe('excelOrdinal', Format(ReportFormat::Excel, 0, 2));
        Obs.Observe('htmlOrdinal', Format(ReportFormat::Html, 0, 2));
        Obs.Expect('html.ok', 'No');
        Obs.Expect('html.err', 'Report 70530 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Obs.Expect('html.len>0', 'No');
        Obs.Expect('pdf.ok', 'No');
        Obs.Expect('pdf.err', 'The object has been run. Use the function CLEAR(Report).');
        Obs.Expect('word.ok', 'No');
        Obs.Expect('word.err', 'The object has been run. Use the function CLEAR(Report).');
        Obs.Expect('excel.ok', 'No');
        Obs.Expect('excel.err', 'The object has been run. Use the function CLEAR(Report).');
        Obs.Expect('xmlOrdinal', '4');
        Obs.Expect('pdfOrdinal', '2');
        Obs.Expect('wordOrdinal', '3');
        Obs.Expect('excelOrdinal', '1');
        Obs.Expect('htmlOrdinal', '5');
        Obs.Verify();
    end;

    [Test]
    procedure TriggerError_InPreReport()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        Ok: Boolean;
    begin
        Seed();
        Rep.SetFailPre();
        Ok := Render(Rep, '', ReportFormat::Xml);
        Obs.Observe('preReportError', 'no error');
        Obs.Observe('ok', Format(Ok));
        Obs.Expect('preReportError', 'no error');
        Obs.Expect('ok', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure SecondSaveAs_OnOneVariable()
    var
        Obs: Codeunit "Probe Observer";
        Rep: Report "LT PnB Rep";
        First: Boolean;
        Second: Boolean;
    begin
        Seed();
        First := Render(Rep, '', ReportFormat::Xml);
        Obs.Observe('first', Format(First));
        Obs.Observe('firstLines', Format(Lines.Count()));
        Second := Render(Rep, '', ReportFormat::Xml);
        Obs.Observe('second', 'no error');
        Obs.Observe('secondResult', Format(Second));
        Obs.Expect('first', 'Yes');
        Obs.Expect('firstLines', '113');
        Obs.Expect('second', 'no error');
        Obs.Expect('secondResult', 'No');
        Obs.Verify();
    end;

    [Test]
    procedure StaticSaveAs_WithParametersString()
    var
        Obs: Codeunit "Probe Observer";
        Row: Record "LT PnB Row";
        Blob: Record "LT PnB Blob";
        OS: OutStream;
        IS: InStream;
        Line: Text;
        Rows: Integer;
    begin
        Seed();
        Blob.DeleteAll();
        Blob.Id := 1;
        Blob.Insert();
        Blob.Data.CreateOutStream(OS);
        Obs.Observe('static.ok', Format(Report.SaveAs(Report::"LT PnB Rep", '', ReportFormat::Xml, OS)));
        Blob.Modify();
        Blob.CalcFields(Data);
        Blob.Data.CreateInStream(IS, TextEncoding::UTF8);
        while not IS.EOS() do begin
            IS.ReadText(Line);
            if StrPos(Line, '<RowId>') > 0 then
                Rows += 1;
        end;
        Obs.Observe('static.rows', Format(Rows));
        Row.SetRange(Id, 1);
        Obs.Observe('filterUntouched', Format(Row.Count()));
        Obs.Expect('static.ok', 'Yes');
        Obs.Expect('static.rows', '0');
        Obs.Expect('filterUntouched', '1');
        Obs.Verify();
    end;
}
