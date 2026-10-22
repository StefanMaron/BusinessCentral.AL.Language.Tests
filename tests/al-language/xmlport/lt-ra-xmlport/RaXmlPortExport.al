// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-occurrence-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), Temp Blob (System Application); own tables 87740, 87741, 87742
// Probe (writer RA, 2026-10-22):
//   1. fieldattribute Occurrence = Optional / Required on EXPORT with an empty value (Text, Code, Integer 0, Date 0D, Boolean false).
//      The import side is AgXmlPortImport.al FieldAttribute_Occurrence_RequiredAndOptional_Import; a fieldattribute without Occurrence and an
//      empty Text exports as attr="" (AtXmlPortFieldElementEdges.al:205); textattribute Occurrence on export: QrXpContainerOccurs.al:474.
//   2. A requestpage with only Caption = '...' and empty layout and actions: static and instance Import and Export. The same shape without
//      Caption is AgXmlPortImport.al RequestPage_EmptySection_ImportAndExport (empty requestpage { }).
//   3. Export of a temporary tableelement with SourceTableView = sorting(B) (no where) over three rows whose B order differs from the primary key
//      order; the same with order(descending); no SourceTableView (control); SetTableView with another key on the port (which wins); and the
//      same view on a temporary child element linked to a parent element. AgXmlPortImport.al TableElement_SourceTableView_Export exports one row only.
// BC versions: 27, 28, 29

table 87740 "LT RA XP Occ Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[30]) { }
        field(3; Cd; Code[20]) { }
        field(4; Num; Integer) { }
        field(5; Dt; Date) { }
        field(6; Flag; Boolean) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 87741 "LT RA XP Line"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; HeadId; Integer) { }
        field(3; B; Code[10]) { }
        field(4; Seq; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByB; B) { }
        key(BySeq; Seq) { }
    }
}

table 87742 "LT RA XP Head"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

xmlport 87743 "LT RA XP Occ Export"
{
    Direction = Both;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RA XP Occ Row")
            {
                fieldattribute(Id; Row.Id) { }
                fieldattribute(OptTxt; Row.Txt) { Occurrence = Optional; }
                fieldattribute(ReqTxt; Row.Txt) { Occurrence = Required; }
                fieldattribute(OptCd; Row.Cd) { Occurrence = Optional; }
                fieldattribute(ReqCd; Row.Cd) { Occurrence = Required; }
                fieldattribute(OptNum; Row.Num) { Occurrence = Optional; }
                fieldattribute(ReqNum; Row.Num) { Occurrence = Required; }
                fieldattribute(OptDt; Row.Dt) { Occurrence = Optional; }
                fieldattribute(ReqDt; Row.Dt) { Occurrence = Required; }
                fieldattribute(OptFlag; Row.Flag) { Occurrence = Optional; }
                fieldattribute(ReqFlag; Row.Flag) { Occurrence = Required; }
            }
        }
    }
}

xmlport 87744 "LT RA XP RP Caption"
{
    Direction = Both;
    Format = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Row; "LT RA XP Occ Row")
            {
                fieldelement(Id; Row.Id) { }
                fieldelement(Txt; Row.Txt) { }
            }
        }
    }

    requestpage
    {
        Caption = 'Some caption';

        layout
        {
        }

        actions
        {
        }
    }
}

xmlport 87745 "LT RA XP View Sorting"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Line; "LT RA XP Line")
            {
                UseTemporary = true;
                SourceTableView = sorting(B);
                fieldattribute(Id; Line.Id) { }
                fieldattribute(B; Line.B) { }
            }
        }
    }

    procedure AddLine(NewId: Integer; NewB: Code[10]; NewSeq: Integer)
    begin
        Line.Init();
        Line.Id := NewId;
        Line.B := NewB;
        Line.Seq := NewSeq;
        Line.Insert();
    end;
}

xmlport 87746 "LT RA XP View Descending"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Line; "LT RA XP Line")
            {
                UseTemporary = true;
                SourceTableView = sorting(B) order(descending);
                fieldattribute(Id; Line.Id) { }
                fieldattribute(B; Line.B) { }
            }
        }
    }

    procedure AddLine(NewId: Integer; NewB: Code[10]; NewSeq: Integer)
    begin
        Line.Init();
        Line.Id := NewId;
        Line.B := NewB;
        Line.Seq := NewSeq;
        Line.Insert();
    end;
}

xmlport 87747 "LT RA XP View None"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Line; "LT RA XP Line")
            {
                UseTemporary = true;
                fieldattribute(Id; Line.Id) { }
                fieldattribute(B; Line.B) { }
            }
        }
    }

    procedure AddLine(NewId: Integer; NewB: Code[10]; NewSeq: Integer)
    begin
        Line.Init();
        Line.Id := NewId;
        Line.B := NewB;
        Line.Seq := NewSeq;
        Line.Insert();
    end;
}

xmlport 87748 "LT RA XP View Linked"
{
    Direction = Export;
    Format = Xml;
    UseRequestPage = false;

    schema
    {
        textelement(Root)
        {
            tableelement(Head; "LT RA XP Head")
            {
                UseTemporary = true;
                fieldattribute(Id; Head.Id) { }
                tableelement(Line; "LT RA XP Line")
                {
                    UseTemporary = true;
                    LinkTable = Head;
                    LinkFields = HeadId = field(Id);
                    SourceTableView = sorting(B);
                    fieldattribute(Id; Line.Id) { }
                    fieldattribute(B; Line.B) { }
                }
            }
        }
    }

    procedure AddHead(NewId: Integer)
    begin
        Head.Init();
        Head.Id := NewId;
        Head.Insert();
    end;

    procedure AddLine(NewId: Integer; NewHeadId: Integer; NewB: Code[10])
    begin
        Line.Init();
        Line.Id := NewId;
        Line.HeadId := NewHeadId;
        Line.B := NewB;
        Line.Insert();
    end;
}

codeunit 87749 "LT RA XP Import Runner"
{
    TableNo = "LT RA XP Occ Row";

    trigger OnRun()
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Row><Id>10</Id><Txt>ten</Txt></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Xmlport.Import(Xmlport::"LT RA XP RP Caption", InS);
    end;
}

codeunit 87750 "LT RA XP Export Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure ReadAll(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InS: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InS, TextEncoding::UTF16);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure StaticExport(XmlportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Xmlport.Export(XmlportId, OutS);
        exit(ReadAll(TempBlob));
    end;

    local procedure OccRows(): Text
    var
        Row: Record "LT RA XP Occ Row";
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ':' + Row.Txt + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure SeedOcc()
    var
        Row: Record "LT RA XP Occ Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Id := 1;
        Row.Insert();
        Row.Init();
        Row.Id := 2;
        Row.Txt := 'two';
        Row.Cd := 'C2';
        Row.Num := 7;
        Row.Dt := DMY2Date(3, 4, 2025);
        Row.Flag := true;
        Row.Insert();
    end;

    [Test]
    procedure RA_FieldAttribute_Occurrence_Export_EmptyValues()
    begin
        SeedOcc();
        Observer.Observe('export', StaticExport(Xmlport::"LT RA XP Occ Export"));
        Observer.Finish();
    end;

    [Test]
    procedure RA_RequestPage_CaptionOnly_ImportAndExport()
    var
        Row: Record "LT RA XP Occ Row";
        Job: Record "LT RA XP Occ Row" temporary;
        TempBlob: Codeunit "Temp Blob";
        Port: XmlPort "LT RA XP RP Caption";
        OutS: OutStream;
        InS: InStream;
    begin
        SeedOcc();
        Observer.Observe('export static', StaticExport(Xmlport::"LT RA XP RP Caption"));
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        ClearLastError();
        Observer.Observe('export instance ok', Format(Port.Export()));
        Observer.Observe('export instance', ReadAll(TempBlob));
        // static import through Codeunit.Run, so an error is caught
        Job.Insert();
        Commit();
        ClearLastError();
        Observer.Observe('import static ok', Format(Codeunit.Run(Codeunit::"LT RA XP Import Runner", Job)));
        Observer.Observe('import static error', GetLastErrorText());
        Observer.Observe('import static rows', OccRows());
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.WriteText('<Root><Row><Id>11</Id><Txt>eleven</Txt></Row></Root>');
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Clear(Port);
        Port.SetSource(InS);
        ClearLastError();
        Observer.Observe('import instance ok', Format(Port.Import()));
        Observer.Observe('import instance rows', OccRows());
        Row.DeleteAll();
        Observer.Finish();
    end;

    local procedure ExportSorting(var Port: XmlPort "LT RA XP View Sorting"): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Port.AddLine(1, 'C', 2);
        Port.AddLine(2, 'A', 3);
        Port.AddLine(3, 'B', 1);
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        exit(ReadAll(TempBlob));
    end;

    [Test]
    procedure RA_TempTableElement_SourceTableViewSorting_ExportOrder()
    var
        Sorting: XmlPort "LT RA XP View Sorting";
        Descending: XmlPort "LT RA XP View Descending";
        NoView: XmlPort "LT RA XP View None";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        // rows: Id 1 B=C Seq 2, Id 2 B=A Seq 3, Id 3 B=B Seq 1
        Observer.Observe('sorting(B)', ExportSorting(Sorting));
        Descending.AddLine(1, 'C', 2);
        Descending.AddLine(2, 'A', 3);
        Descending.AddLine(3, 'B', 1);
        TempBlob.CreateOutStream(OutS);
        Descending.SetDestination(OutS);
        Descending.Export();
        Observer.Observe('sorting(B) order(descending)', ReadAll(TempBlob));
        NoView.AddLine(1, 'C', 2);
        NoView.AddLine(2, 'A', 3);
        NoView.AddLine(3, 'B', 1);
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        NoView.SetDestination(OutS);
        NoView.Export();
        Observer.Observe('no SourceTableView', ReadAll(TempBlob));
        Observer.Finish();
    end;

    [Test]
    procedure RA_TempTableElement_SourceTableViewSorting_WithSetTableView()
    var
        SortingSeq: XmlPort "LT RA XP View Sorting";
        SortingSeqDesc: XmlPort "LT RA XP View Sorting";
        SortingFilter: XmlPort "LT RA XP View Sorting";
        ViewSeq: Record "LT RA XP Line";
        ViewSeqDesc: Record "LT RA XP Line";
        ViewFilter: Record "LT RA XP Line";
    begin
        ViewSeq.SetCurrentKey(Seq);
        SortingSeq.SetTableView(ViewSeq);
        Observer.Observe('SetTableView sorting(Seq)', ExportSorting(SortingSeq));
        ViewSeqDesc.SetCurrentKey(Seq);
        ViewSeqDesc.Ascending(false);
        SortingSeqDesc.SetTableView(ViewSeqDesc);
        Observer.Observe('SetTableView sorting(Seq) descending', ExportSorting(SortingSeqDesc));
        ViewFilter.SetRange(B, 'B', 'C');
        SortingFilter.SetTableView(ViewFilter);
        Observer.Observe('SetTableView filter only', ExportSorting(SortingFilter));
        Observer.Finish();
    end;

    [Test]
    procedure RA_TempChildTableElement_Linked_SourceTableViewSorting_ExportOrder()
    var
        Port: XmlPort "LT RA XP View Linked";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Port.AddHead(1);
        Port.AddHead(2);
        Port.AddLine(1, 1, 'C');
        Port.AddLine(2, 2, 'B');
        Port.AddLine(3, 1, 'A');
        Port.AddLine(4, 2, 'A');
        Port.AddLine(5, 1, 'B');
        TempBlob.CreateOutStream(OutS);
        Port.SetDestination(OutS);
        Port.Export();
        Observer.Observe('linked sorting(B)', ReadAll(TempBlob));
        Observer.Finish();
    end;
}
