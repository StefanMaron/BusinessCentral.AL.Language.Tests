// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (Base Application); self-contained table 71758, reports 71759 and 71761, test codeunit 71762
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the element names Report.SaveAs(Xml) writes for data item names that contain dots, slashes and spaces: a dot, a slash, a run of dots, a dot next to a space, a double space,
// a leading or trailing dot; and what happens when two names map to the same element name. Column names cannot contain a dot, slash or space: AL0379 (the name does not comply with the Common Language Specification) on AL 16, 17 and 18. Complements ReportSaveAsDataItems.al (which pins "Prod. Order Line", "Sales/Line", hyphen and ampersand).
// BC versions: 29 (27 and 28 by CI)

table 71758 "LT DN Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

report 71759 "LT DN Items"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem("A. B"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(ABId; Id) { }
        }
        dataitem("C/D"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(CDId; Id) { }
        }
        dataitem("E.F"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(EFId; Id) { }
        }
        dataitem("G..H"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(GHId; Id) { }
        }
        dataitem("I./J"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(IJId; Id) { }
        }
        dataitem("K  L"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(KLId; Id) { }
        }
        dataitem("M."; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(MId; Id) { }
        }
        dataitem(".N"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(NId; Id) { }
        }
        dataitem("O. . P"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(OPId; Id) { }
        }
        dataitem("Q//R"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(QRId; Id) { }
        }
    }
}

report 71761 "LT DN Collisions"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem("X.Y"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(ZId; Id) { }
            column(ZName; Name) { }
        }
        dataitem("X/Y"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(Plain; Id) { }
        }
        dataitem("X_Y"; "LT DN Row")
        {
            DataItemTableView = where(Id = const(1));
            column(Plain2; Id) { }
        }
    }
}

codeunit 71762 "LT Report Dataset Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT DN Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Commit();
    end;

    local procedure StripSystemIds(Xml: Text): Text
    var
        Result: Text;
        At: Integer;
        Marker: Text;
    begin
        // systemId (a Guid) and tableId are written from BC 28 only.
        Marker := ' systemId="';
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Result += CopyStr(Xml, 1, At - 1);
            Xml := CopyStr(Xml, At + StrLen(Marker) + 37);
            At := StrPos(Xml, Marker);
        end;
        Xml := Result + Xml;
        Result := '';
        Marker := ' tableId="';
        At := StrPos(Xml, Marker);
        while At > 0 do begin
            Result += CopyStr(Xml, 1, At - 1);
            Xml := CopyStr(Xml, At + StrLen(Marker));
            Xml := CopyStr(Xml, StrPos(Xml, '"') + 1);
            At := StrPos(Xml, Marker);
        end;
        exit(Result + Xml);
    end;

    local procedure DataItemsOf(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Xml: Text;
        Line: Text;
        At: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(ReportId, '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Xml += Line + '|';
        end;
        Xml := StripSystemIds(Xml);
        At := StrPos(Xml, '<DataItems>');
        if At = 0 then
            exit('no DataItems element');
        exit(CopyStr(Xml, At));
    end;

    [Test]
    procedure SaveAsXml_DataItemNames_DotsAndSlashes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tree', DataItemsOf(Report::"LT DN Items"));
        Observer.Finish();
    end;

    [Test]
    procedure SaveAsXml_Names_MappingToTheSameElement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('tree', DataItemsOf(Report::"LT DN Collisions"));
        Observer.Finish();
    end;
}
