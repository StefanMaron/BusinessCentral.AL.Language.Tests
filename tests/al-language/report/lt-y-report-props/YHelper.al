// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob and Data Compression (System Application)
// Probe: written against BC service tiers of the corpus matrix; every literal asserted in the tests of this folder is what the tier produced.
// Facts: helper and shared state of the writer Y probes (reports 75501-75549): SaveAs wrappers, a zip entry reader, a row dumper and a SingleInstance store for values seen in handlers.
// BC versions: 27-29 (version differences are guarded)

codeunit 75500 "LT Y Helper"
{
    procedure SaveAsText(ReportId: Integer; Format: ReportFormat): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    // The DataItems part of the SaveAs Xml text (the header before it is not asserted), without systemId and tableId attributes.
    procedure DataItemsXml(ReportId: Integer): Text
    var
        Xml: Text;
        At: Integer;
    begin
        Xml := StripAttribute(StripAttribute(SaveAsText(ReportId, ReportFormat::Xml), ' systemId="', 37), ' tableId="', 0);
        At := StrPos(Xml, '<DataItems>');
        if At = 0 then
            exit('no DataItems element');
        exit(CopyStr(Xml, At));
    end;

    local procedure StripAttribute(Xml: Text; Marker: Text; FixedLength: Integer): Text
    var
        Result: Text;
        At: Integer;
    begin
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Result += CopyStr(Xml, 1, At - 1);
            if FixedLength > 0 then
                Xml := CopyStr(Xml, At + StrLen(Marker) + FixedLength)
            else begin
                Xml := CopyStr(Xml, At + StrLen(Marker));
                Xml := CopyStr(Xml, StrPos(Xml, '"') + 1);
            end;
            At := StrPos(Xml, Marker);
        end;
        exit(Result + Xml);
    end;

    // Size of the rendered file, the first bytes as text, and nothing else.
    procedure SaveAsSize(ReportId: Integer; Format: ReportFormat): Integer
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        exit(TempBlob.Length());
    end;

    procedure SaveAsHead(ReportId: Integer; Format: ReportFormat; Count: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Buffer: Text;
        Head: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        TempBlob.CreateInStream(InS);
        InS.Read(Buffer, Count);
        Head := Buffer;
        exit(Head);
    end;

    // Entry names of the zip file a SaveAs Excel or Word writes, in the order the archive lists them.
    procedure ZipEntries(ReportId: Integer; Format: ReportFormat): Text
    var
        TempBlob: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        OutS: OutStream;
        InS: InStream;
        Names: List of [Text];
        Name: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        DataCompression.GetEntryList(Names);
        DataCompression.CloseZipArchive();
        foreach Name in Names do
            Result += Name + ';';
        exit(Result);
    end;

    // Text of one entry of a zip file written by SaveAs.
    procedure ZipEntryText(ReportId: Integer; Format: ReportFormat; EntryName: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Entry: Codeunit "Temp Blob";
        DataCompression: Codeunit "Data Compression";
        OutS: OutStream;
        InS: InStream;
        EntryOut: OutStream;
        EntryIn: InStream;
        Line: Text;
        Result: Text;
        Length: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', Format, OutS);
        TempBlob.CreateInStream(InS);
        DataCompression.OpenZipArchive(InS, false);
        Entry.CreateOutStream(EntryOut);
        DataCompression.ExtractEntry(EntryName, EntryOut, Length);
        DataCompression.CloseZipArchive();
        Entry.CreateInStream(EntryIn);
        while not EntryIn.EOS() do begin
            EntryIn.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    // Every non-blob column of the current row as name=value; used for system table rows (Report Layout List, Report Metadata, XmlPort Metadata).
    procedure DumpRow(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if not (FR.Type in [FieldType::Blob, FieldType::Media, FieldType::MediaSet, FieldType::Guid, FieldType::DateTime]) then
                Result += FR.Name + '=' + Format(FR.Value) + ';';
        end;
        exit(Result);
    end;

    procedure RowOf(TableNo: Integer; KeyField: Integer; Id: Integer): Text
    var
        RR: RecordRef;
        FR: FieldRef;
        Result: Text;
    begin
        RR.Open(TableNo);
        FR := RR.Field(KeyField);
        FR.SetRange(Id);
        if RR.FindFirst() then
            Result := DumpRow(RR)
        else
            Result := 'no row';
        RR.Close();
        exit(Result);
    end;

    // The rows of Report Layout List (2000000234) of one report: one entry per layout, all columns.
    procedure LayoutRows(ReportId: Integer): Text
    var
        LayoutList: Record "Report Layout List";
        RR: RecordRef;
        Result: Text;
    begin
        LayoutList.SetRange("Report ID", ReportId);
        if LayoutList.FindSet() then
            repeat
                RR.GetTable(LayoutList);
                Result += '[' + DumpRow(RR) + ']';
            until LayoutList.Next() = 0
        else
            Result := 'no layouts';
        exit(Result);
    end;

    // The rows of Report Data Items of one report: one entry per data item, all columns.
    procedure DataItemRows(ReportId: Integer): Text
    var
        Items: Record "Report Data Items";
        RR: RecordRef;
        Result: Text;
    begin
        Items.SetRange("Report ID", ReportId);
        if Items.FindSet() then
            repeat
                RR.GetTable(Items);
                Result += '[' + DumpRow(RR) + ']';
            until Items.Next() = 0
        else
            Result := 'no data items';
        exit(Result);
    end;

    procedure Failed(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;
}

codeunit 75501 "LT Y Seen"
{
    SingleInstance = true;

    var
        Entries: Dictionary of [Text, Text];

    procedure Put(Name: Text; Value: Text)
    begin
        if Entries.ContainsKey(Name) then
            Entries.Set(Name, Value)
        else
            Entries.Add(Name, Value);
    end;

    procedure Get(Name: Text): Text
    begin
        if Entries.ContainsKey(Name) then
            exit(Entries.Get(Name));
        exit('<none>');
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;
}
