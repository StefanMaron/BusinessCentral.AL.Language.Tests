// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 69040..69042, enum 69043, pages 69044..69048, codeunit 69049
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what the Page Metadata, Field, Key and Table Metadata system tables read from a declaration:
//  - Page Metadata: Caption is the Caption literal, else the English CaptionML, else the page name (a Locked caption reads as written);
//    CardPageID is the id of the page CardPageId names, 0 when none;
//  - Field: TableName is the table name; Class Normal, FlowField or FlowFilter; Enabled is false for Enabled = false (the field is
//    still a row); "Field Caption" is Caption, else the English CaptionML, else the field name; the system fields read the
//    captions System ID, Created At, Created By, Modified At, Modified By, and Created By and Modified By relate to table
//    2000000120 (User) field 0; RelationTableNo / RelationFieldNo of a plain relation is the table and field (also with a where
//    filter or const condition), and 0 / 0 of a CONDITIONAL relation (if ... else if ...);
//  - Key: MaintainSIFTIndex is true only for a key that has SumIndexFields (and says so), false for the primary key, for a key
//    with MaintainSIFTIndex = false and for a key with none; ObsoleteState Pending reads Pending, else No; the table has a fifth,
//    hidden key $systemId;
//  - Table Metadata: DrillDownPageID and LookupPageID are the page ids the properties name, 0 when unset.
// BC versions: 27.5

table 69040 "Probe MD Target"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "Probe MD Card";

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 69041 "Probe MD NoDrill"
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

enum 69043 "Probe MD Kind"
{
    Extensible = true;

    value(0; A) { }
    value(1; B) { }
}

table 69042 "Probe MD Table"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "Probe MD List";
    LookupPageId = "Probe MD List";

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "Probe MD Kind") { }
        field(3; Rel; Code[10])
        {
            TableRelation = if (Kind = const(A)) "Probe MD Target".Id else if (Kind = const(B)) "Probe MD NoDrill".Id;
            ValidateTableRelation = false;
        }
        field(4; Rel2; Integer)
        {
            TableRelation = "Probe MD Target".Id where(Id = filter(<> 5));
            TestTableRelation = false;
        }
        field(5; Cap1; Integer) { Caption = 'Field caption'; }
        field(6; CapML; Integer) { CaptionML = ENU = 'ML caption', DEU = 'ML Bezeichnung'; }
        field(7; NoCap; Integer) { }
        field(8; Dis; Integer) { Enabled = false; }
        field(9; Flow; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Probe MD Target");
        }
        field(10; Filt; Integer) { FieldClass = FlowFilter; }
        field(11; Rel3; Integer) { TableRelation = "Probe MD Target".Id where(Id = const(7)); }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Cap1) { MaintainSIFTIndex = false; }
        key(K3; NoCap) { SumIndexFields = CapML; }
        key(K4; CapML)
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'probe';
            ObsoleteTag = '1.0';
        }
    }
}

page 69044 "Probe MD List"
{
    PageType = List;
    SourceTable = "Probe MD Table";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'MD list caption';
    CardPageId = "Probe MD Card";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
            }
        }
    }
}

page 69045 "Probe MD Card"
{
    PageType = Card;
    SourceTable = "Probe MD Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

page 69046 "Probe MD CaptionML"
{
    PageType = Card;
    SourceTable = "Probe MD Table";
    ApplicationArea = All;
    UsageCategory = None;
    CaptionML = ENU = 'ML page caption', DEU = 'ML Seite';

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

page 69047 "Probe MD Locked"
{
    PageType = Card;
    SourceTable = "Probe MD Table";
    ApplicationArea = All;
    UsageCategory = None;
    Caption = 'Locked caption', Locked = true;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

codeunit 69049 "Probe Metadata Declaration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure PageMetadata_CaptionAndCardPageId_FromTheDeclaration()
    var
        PageMeta: Record "Page Metadata";
    begin
        PageMeta.Get(Page::"Probe MD List");
        Assert.AreEqual('MD list caption', PageMeta.Caption, 'Caption literal');
        Assert.AreEqual(Page::"Probe MD Card", PageMeta.CardPageID, 'CardPageId');
        PageMeta.Get(Page::"Probe MD CaptionML");
        Assert.AreEqual('ML page caption', PageMeta.Caption, 'CaptionML ENU');
        Assert.AreEqual(0, PageMeta.CardPageID, 'no CardPageId');
        PageMeta.Get(Page::"Probe MD Card");
        Assert.AreEqual('Probe MD Card', PageMeta.Caption, 'the page name');
        PageMeta.Get(Page::"Probe MD Locked");
        Assert.AreEqual('Locked caption', PageMeta.Caption, 'Locked caption');
    end;

    local procedure FieldRow(FieldName: Text; var FieldRec: Record Field)
    begin
        FieldRec.SetRange(TableNo, Database::"Probe MD Table");
        FieldRec.SetRange(FieldName, FieldName);
        FieldRec.FindFirst();
    end;

    [Test]
    procedure Field_TableNameClassEnabledCaption_FromTheDeclaration()
    var
        FieldRec: Record Field;
    begin
        FieldRow('Id', FieldRec);
        Assert.AreEqual('Probe MD Table', FieldRec.TableName, 'TableName');
        Assert.AreEqual(FieldRec.Class::Normal, FieldRec.Class, 'Normal');
        Assert.IsTrue(FieldRec.Enabled, 'Enabled');
        Assert.AreEqual('Id', FieldRec."Field Caption", 'caption is the name');

        FieldRow('Flow', FieldRec);
        Assert.AreEqual(FieldRec.Class::FlowField, FieldRec.Class, 'FlowField');
        FieldRow('Filt', FieldRec);
        Assert.AreEqual(FieldRec.Class::FlowFilter, FieldRec.Class, 'FlowFilter');
        FieldRow('Dis', FieldRec);
        Assert.IsFalse(FieldRec.Enabled, 'Enabled = false still has a row, disabled');
        FieldRow('Cap1', FieldRec);
        Assert.AreEqual('Field caption', FieldRec."Field Caption", 'Caption');
        FieldRow('CapML', FieldRec);
        Assert.AreEqual('ML caption', FieldRec."Field Caption", 'CaptionML ENU');
        FieldRow('NoCap', FieldRec);
        Assert.AreEqual('NoCap', FieldRec."Field Caption", 'no caption');

        FieldRow('$systemId', FieldRec);
        Assert.AreEqual('System ID', FieldRec."Field Caption", 'SystemId');
        FieldRow('SystemCreatedAt', FieldRec);
        Assert.AreEqual('Created At', FieldRec."Field Caption", 'SystemCreatedAt');
        FieldRow('SystemCreatedBy', FieldRec);
        Assert.AreEqual('Created By', FieldRec."Field Caption", 'SystemCreatedBy');
        Assert.AreEqual(2000000120, FieldRec.RelationTableNo, 'SystemCreatedBy relates to User');
        Assert.AreEqual(0, FieldRec.RelationFieldNo, 'field 0');
        FieldRow('SystemModifiedAt', FieldRec);
        Assert.AreEqual('Modified At', FieldRec."Field Caption", 'SystemModifiedAt');
        FieldRow('SystemModifiedBy', FieldRec);
        Assert.AreEqual('Modified By', FieldRec."Field Caption", 'SystemModifiedBy');
    end;

    [Test]
    procedure Field_RelationTableAndField_PlainAndConditional()
    var
        FieldRec: Record Field;
    begin
        FieldRow('Rel2', FieldRec);
        Assert.AreEqual(Database::"Probe MD Target", FieldRec.RelationTableNo, 'plain relation with a filter');
        Assert.AreEqual(1, FieldRec.RelationFieldNo, 'plain relation field');
        FieldRow('Rel3', FieldRec);
        Assert.AreEqual(Database::"Probe MD Target", FieldRec.RelationTableNo, 'relation with a const condition');
        Assert.AreEqual(1, FieldRec.RelationFieldNo, 'const condition field');
        FieldRow('Rel', FieldRec);
        Assert.AreEqual(0, FieldRec.RelationTableNo, 'conditional relation: table');
        Assert.AreEqual(0, FieldRec.RelationFieldNo, 'conditional relation: field');
    end;

    [Test]
    procedure Key_MaintainSIFTIndexAndObsoleteState_FromTheDeclaration()
    var
        KeyRec: Record "Key";
        Rows: Text;
    begin
        KeyRec.SetRange(TableNo, Database::"Probe MD Table");
        KeyRec.FindSet();
        repeat
            Rows += Format(KeyRec."No.") + ' [' + KeyRec.Key + '] sift=' + Format(KeyRec.MaintainSIFTIndex) + ' obsolete=' + Format(KeyRec.ObsoleteState) + '; ';
        until KeyRec.Next() = 0;

        Assert.AreEqual(
            '1 [Id] sift=No obsolete=No; 2 [Cap1] sift=No obsolete=No; 3 [NoCap] sift=Yes obsolete=No; 4 [CapML] sift=No obsolete=Pending; 5 [$systemId] sift=No obsolete=No; ',
            Rows, 'keys');
    end;

    [Test]
    procedure TableMetadata_DrillDownAndLookupPageId_FromTheDeclaration()
    var
        TableMeta: Record "Table Metadata";
    begin
        TableMeta.Get(Database::"Probe MD Table");
        Assert.AreEqual(Page::"Probe MD List", TableMeta.DrillDownPageID, 'DrillDownPageId');
        Assert.AreEqual(Page::"Probe MD List", TableMeta.LookupPageID, 'LookupPageId');
        TableMeta.Get(Database::"Probe MD Target");
        Assert.AreEqual(Page::"Probe MD Card", TableMeta.DrillDownPageID, 'only DrillDownPageId set');
        Assert.AreEqual(0, TableMeta.LookupPageID, 'LookupPageId unset');
        TableMeta.Get(Database::"Probe MD NoDrill");
        Assert.AreEqual(0, TableMeta.DrillDownPageID, 'none set');
    end;
}
