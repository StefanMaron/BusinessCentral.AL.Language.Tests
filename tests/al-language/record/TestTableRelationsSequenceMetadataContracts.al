// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: shared Assert (60021); "Probe MD Target" (69040), "Probe MD NoDrill" (69041), "Probe MD Kind" (69043) from
//                record/TestPlatformMetadataDeclarationContracts.al; self-contained table 69050, page 69051, codeunit 69052
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - "Table Relations Metadata" columns Condition Field No., Condition Type, Condition Value, Test Table Relation, Validate Table Relation:
//      * a conditional relation (if (Kind = const(A)) T1.Id else if (Kind = const(B)) T2.Id) gives one row per arm, both with Condition No.
//        1, Condition Field No. the field of Kind, Condition Type CONST, Condition Value the ordinal of the member (A is '0', B is '1'), and
//        Validate Table Relation false and Test Table Relation false when ValidateTableRelation = false is declared;
//      * the same for an Option condition (Condition Value '1' for const(Y));
//      * an unconditional relation gives Condition Field No. 0, Condition Type CONST, an empty Condition Value; Validate Table Relation
//        true and Test Table Relation false (also for a relation with a where filter); TestTableRelation = false changes nothing here;
//      * the relations the system fields SystemCreatedBy and SystemModifiedBy carry (User, field 1) read Test Table Relation true and
//        Validate Table Relation false;
//  - "Page Control Field" Sequence numbers the field controls in declaration order from 0, counting the controls inside a group
//    (Id 0, Kind 1, Opt 2, Rel4 3).
// BC versions: 27.5

table 69050 "Probe TR Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "Probe MD Kind") { }
        field(3; Opt; Option) { OptionMembers = X,Y; }
        field(4; Rel; Code[10])
        {
            TableRelation = if (Kind = const(A)) "Probe MD Target".Id else if (Kind = const(B)) "Probe MD NoDrill".Id;
            ValidateTableRelation = false;
        }
        field(5; Rel2; Integer)
        {
            TableRelation = "Probe MD Target".Id where(Id = filter(<> 5));
            TestTableRelation = false;
        }
        field(6; Rel3; Integer) { TableRelation = if (Opt = const(Y)) "Probe MD Target".Id; }
        field(7; Rel4; Integer) { TableRelation = "Probe MD Target".Id; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 69051 "Probe TR Page"
{
    PageType = Card;
    SourceTable = "Probe TR Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            group(G1)
            {
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Opt; Rec.Opt) { ApplicationArea = All; }
            }
            field(Rel4; Rec.Rel4) { ApplicationArea = All; }
        }
    }
}

codeunit 69052 "Probe Relations Sequence"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableRelationsMetadata_ConditionAndFlagColumns()
    var
        Relations: Record "Table Relations Metadata";
        Rows: Text;
    begin
        Relations.SetRange("Table ID", Database::"Probe TR Table");
        Relations.FindSet();
        repeat
            Rows += 'f' + Format(Relations."Field No.") + ' rel' + Format(Relations."Relation No.") + ' cond' + Format(Relations."Condition No.") +
                ' -> T' + Format(Relations."Related Table ID") + '.' + Format(Relations."Related Field No.") +
                ' condField=' + Format(Relations."Condition Field No.") + ' type=' + Format(Relations."Condition Type") +
                ' value=[' + Relations."Condition Value" + '] test=' + Format(Relations."Test Table Relation") +
                ' validate=' + Format(Relations."Validate Table Relation") + '; ';
        until Relations.Next() = 0;

        Assert.AreEqual(
            'f4 rel1 cond1 -> T69040.1 condField=2 type=CONST value=[0] test=No validate=No; ' +
            'f4 rel2 cond1 -> T69041.1 condField=2 type=CONST value=[1] test=No validate=No; ' +
            'f5 rel1 cond1 -> T69040.1 condField=0 type=CONST value=[] test=No validate=Yes; ' +
            'f6 rel1 cond1 -> T69040.1 condField=3 type=CONST value=[1] test=No validate=Yes; ' +
            'f7 rel1 cond1 -> T69040.1 condField=0 type=CONST value=[] test=No validate=Yes; ' +
            'f2000000002 rel1 cond1 -> T2000000120.1 condField=0 type=CONST value=[] test=Yes validate=No; ' +
            'f2000000004 rel1 cond1 -> T2000000120.1 condField=0 type=CONST value=[] test=Yes validate=No; ',
            Rows, 'relations');
    end;

    [Test]
    procedure PageControlField_Sequence_FollowsDeclarationOrderFromZero()
    var
        Controls: Record "Page Control Field";
        Rows: Text;
    begin
        Controls.SetRange(PageNo, Page::"Probe TR Page");
        Controls.SetCurrentKey(Sequence);
        Controls.FindSet();
        repeat
            Rows += Controls.ControlName + '=' + Format(Controls.Sequence) + ' ';
        until Controls.Next() = 0;

        Assert.AreEqual('Id=0 Kind=1 Opt=2 Rel4=3 ', Rows, 'sequence');
    end;
}
