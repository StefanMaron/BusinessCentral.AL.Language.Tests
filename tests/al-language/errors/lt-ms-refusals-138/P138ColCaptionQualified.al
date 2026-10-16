// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-includecaption-property
// Scope: in-scope
// Fixtures used: self-contained tables 74510, 74511, report 74512, codeunit 74513
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
//
// Facts: Report.SaveAs(Xml): the Labels block and the Column lines of columns with IncludeCaption = true whose source is a field written with its data item name
// (the own item, the parent item from a nested item); the label name, the caption text, the column value.

table 74510 "LT P138 Col Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Parent Id cap'; }
        field(2; Name; Text[30]) { Caption = 'Parent Name cap'; }
        field(3; Qty; Decimal) { Caption = 'Parent Qty cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 74511 "LT P138 Col Child"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Child Id cap'; }
        field(2; ParentId; Integer) { Caption = 'Child ParentId cap'; }
        field(3; Note; Text[30]) { Caption = 'Child Note cap'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 74512 "LT P138 Col Qualified"
{
    ProcessingOnly = false;
    DefaultLayout = RDLC;
    UseRequestPage = false;

    dataset
    {
        dataitem(Parent; "LT P138 Col Parent")
        {
            column(POwn; Name) { IncludeCaption = true; }
            column(PQual; Parent.Name) { IncludeCaption = true; }
            column(PQualQty; Parent.Qty) { IncludeCaption = true; }

            dataitem(Child; "LT P138 Col Child")
            {
                DataItemLink = ParentId = field(Id);

                column(COwn; Note) { IncludeCaption = true; }
                column(CQual; Child.Note) { IncludeCaption = true; }
                column(CFromParent; Parent.Name) { IncludeCaption = true; }
                column(CFromParentId; Parent.Id) { IncludeCaption = true; }
            }
        }
    }
}

codeunit 74513 "LT P138 Col Caption Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT P138 Col Parent";
        Child: Record "LT P138 Col Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'P1';
        Parent.Qty := 2.5;
        Parent.Insert();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Note := 'C1';
        Child.Insert();
    end;

    local procedure DatasetLines(Keep: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        Report.SaveAs(Report::"LT P138 Col Qualified", '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            if Line.Trim().StartsWith(Keep) then
                Result += '[' + Line.Trim() + ']';
        end;
        exit(Result);
    end;

    [Test]
    procedure P138_Labels_OfQualifiedSources()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('labels', DatasetLines('<Label '));
        Observer.Expect('labels', '[<Label name="POwnCaption">Parent Name cap</Label>][<Label name="PQualCaption">Parent Name cap</Label>][<Label name="PQualQtyCaption">Parent Qty cap</Label>][<Label name="COwnCaption">Child Note cap</Label>][<Label name="CQualCaption">Child Note cap</Label>][<Label name="CFromParentCaption">Parent Name cap</Label>][<Label name="CFromParentIdCaption">Parent Id cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Columns_OfQualifiedSources()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('columns', DatasetLines('<Column '));
        Observer.Expect('columns', '[<Column name="POwn">P1</Column>][<Column name="PQual">P1</Column>][<Column name="PQualQty" decimalformatter="#,##0.00">2.5</Column>][<Column name="COwn">C1</Column>][<Column name="CQual">C1</Column>][<Column name="CFromParent">P1</Column>][<Column name="CFromParentId">1</Column>]');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Labels_WhenNoRows()
    var
        Parent: Record "LT P138 Col Parent";
        Child: Record "LT P138 Col Child";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Observer.Observe('labels_no_rows', DatasetLines('<Label '));
        Observer.Expect('labels_no_rows', '[<Label name="POwnCaption">Parent Name cap</Label>][<Label name="PQualCaption">Parent Name cap</Label>][<Label name="PQualQtyCaption">Parent Qty cap</Label>][<Label name="COwnCaption">Child Note cap</Label>][<Label name="CQualCaption">Child Note cap</Label>][<Label name="CFromParentCaption">Parent Name cap</Label>][<Label name="CFromParentIdCaption">Parent Id cap</Label>]');
        Observer.Verify();
    end;

    [Test]
    procedure P138_Labels_ParentOnlyNoChild()
    var
        Parent: Record "LT P138 Col Parent";
        Child: Record "LT P138 Col Child";
        Observer: Codeunit "Probe Observer";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'P1';
        Parent.Insert();
        Observer.Observe('labels_parent_only', DatasetLines('<Label '));
        Observer.Observe('columns_parent_only', DatasetLines('<Column '));
        Observer.Expect('labels_parent_only', '[<Label name="POwnCaption">Parent Name cap</Label>][<Label name="PQualCaption">Parent Name cap</Label>][<Label name="PQualQtyCaption">Parent Qty cap</Label>][<Label name="COwnCaption">Child Note cap</Label>][<Label name="CQualCaption">Child Note cap</Label>][<Label name="CFromParentCaption">Parent Name cap</Label>][<Label name="CFromParentIdCaption">Parent Id cap</Label>]');
        Observer.Expect('columns_parent_only', '[<Column name="POwn">P1</Column>][<Column name="PQual">P1</Column>][<Column name="PQualQty" decimalformatter="#,##0.00">0</Column>]');
        Observer.Verify();
    end;
}
