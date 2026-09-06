// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: CFSF Header (60816), CFSF Line (60817)
// BC versions: 27.0+
//
// A CalcFormula, and a TableRelation, may name one of the system fields BC gives every table
// (SystemId, SystemCreatedAt, SystemCreatedBy, SystemModifiedAt, SystemModifiedBy) even
// though no table declares them. Base Application ships FlowFields of exactly this shape —
// "Sales Header Archive"."Last Archived Date" is max(... .SystemCreatedAt ...) — and every
// API page's foreign key is TableRelation = <Table>.SystemId.
//
// Nothing in the corpus pinned it. The three positions a system field can occupy are three
// separate resolution sites, and they fail differently: a missing SOURCE field loses the
// whole formula, while a missing where-arm is dropped and the field still calculates, on the
// wrong set of rows. So each test below asserts a value that a dropped arm cannot produce.
//
// Seeded once, in Initialize():
//
//   Header  Line  Doc No.  Header Sys Id      Amount
//   D1      1     D1       D1.SystemId          100
//   D1      2     D1       D1.SystemId           25
//   D1      3     D1       (an unrelated GUID)  900
//
//   Line Count (ordinary arm)     3        Line Count By Sys Id      2
//   Total Amount (ordinary arm)   1025     Amount By Sys Id          125
//
// 3 and 1025 are what the SystemId arms answer if the arm is dropped; 0 is what they answer
// if the link never matches. Neither is 2 or 125.
codeunit 60818 "CFSF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(var CfsfHeader: Record "CFSF Header")
    var
        CfsfLine: Record "CFSF Line";
        UnrelatedId: Guid;
    begin
        CfsfLine.Reset();
        CfsfLine.DeleteAll();
        CfsfHeader.Reset();
        CfsfHeader.DeleteAll();

        CfsfHeader.Init();
        CfsfHeader."No." := 'D1';
        CfsfHeader.Insert(true);
        CfsfHeader.Get('D1');

        AddLine(1, 'D1', CfsfHeader.SystemId, 100);
        AddLine(2, 'D1', CfsfHeader.SystemId, 25);

        UnrelatedId := CreateGuid();
        AddLine(3, 'D1', UnrelatedId, 900);
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; HeaderSysId: Guid; LineAmount: Decimal)
    var
        CfsfLine: Record "CFSF Line";
    begin
        CfsfLine.Init();
        CfsfLine."Entry No." := EntryNo;
        CfsfLine."Doc No." := DocNo;
        CfsfLine."Header Sys Id" := HeaderSysId;
        CfsfLine.Amount := LineAmount;
        CfsfLine.Insert(true);
    end;

    /// The ordinary-field baselines. Every system-field answer below has to differ from these.
    [Test]
    procedure Record_CalcFields_OrdinaryWhereArm_Baseline()
    var
        CfsfHeader: Record "CFSF Header";
    begin
        Initialize(CfsfHeader);

        CfsfHeader.CalcFields("Line Count", "Total Amount");

        Assert.AreEqual(3, CfsfHeader."Line Count", 'count() over an ordinary where-arm');
        Assert.AreEqual(1025.0, CfsfHeader."Total Amount", 'sum() over an ordinary where-arm');
    end;

    /// where("Header Sys Id" = field(SystemId)) — the parent side of the arm is a system field.
    [Test]
    procedure Record_CalcFields_WhereArmLinksToParentSystemId()
    var
        CfsfHeader: Record "CFSF Header";
    begin
        Initialize(CfsfHeader);

        CfsfHeader.CalcFields("Line Count By Sys Id", "Amount By Sys Id");

        Assert.AreEqual(2, CfsfHeader."Line Count By Sys Id", 'count() where(... = field(SystemId))');
        Assert.AreEqual(125.0, CfsfHeader."Amount By Sys Id", 'sum() where(... = field(SystemId))');
    end;

    /// max()/min() over SystemCreatedAt — the aggregated source field is a system field.
    [Test]
    procedure Record_CalcFields_AggregatesSourceSystemCreatedAt()
    var
        CfsfHeader: Record "CFSF Header";
        CfsfLine: Record "CFSF Line";
        Earliest: DateTime;
        Latest: DateTime;
    begin
        Initialize(CfsfHeader);

        CfsfLine.SetRange("Doc No.", 'D1');
        CfsfLine.FindSet();
        Earliest := CfsfLine.SystemCreatedAt;
        Latest := CfsfLine.SystemCreatedAt;
        repeat
            if CfsfLine.SystemCreatedAt < Earliest then
                Earliest := CfsfLine.SystemCreatedAt;
            if CfsfLine.SystemCreatedAt > Latest then
                Latest := CfsfLine.SystemCreatedAt;
        until CfsfLine.Next() = 0;
        Assert.AreNotEqual(0DT, Latest, 'the seeded lines must carry a SystemCreatedAt');

        CfsfHeader.CalcFields("Last Line Created At", "First Line Created At");

        Assert.AreEqual(Latest, CfsfHeader."Last Line Created At", 'max() over SystemCreatedAt');
        Assert.AreEqual(Earliest, CfsfHeader."First Line Created At", 'min() over SystemCreatedAt');
    end;

    /// lookup() of SystemCreatedBy — the looked-up source field is a system field.
    [Test]
    procedure Record_CalcFields_LooksUpSourceSystemCreatedBy()
    var
        CfsfHeader: Record "CFSF Header";
        CfsfLine: Record "CFSF Line";
    begin
        Initialize(CfsfHeader);
        CfsfLine.Get(1);

        CfsfHeader.CalcFields("Line Created By");

        Assert.AreEqual(CfsfLine.SystemCreatedBy, CfsfHeader."Line Created By", 'lookup() of SystemCreatedBy');
        Assert.AreNotEqual(CreateGuid(), CfsfHeader."Line Created By", 'lookup() of SystemCreatedBy is not an arbitrary GUID');
    end;

    /// where(SystemCreatedBy = field("Owner Id")) — the source-table side of the arm is a
    /// system field. Positive and negative in one test, because the discriminator is that the
    /// arm constrains the row set at all.
    [Test]
    procedure Record_CalcFields_WhereArmFiltersSourceSystemCreatedBy()
    var
        CfsfHeader: Record "CFSF Header";
        CfsfLine: Record "CFSF Line";
    begin
        Initialize(CfsfHeader);
        CfsfLine.Get(1);

        CfsfHeader."Owner Id" := CfsfLine.SystemCreatedBy;
        CfsfHeader.Modify(true);
        CfsfHeader.CalcFields("Line Count By Creator");
        Assert.AreEqual(3, CfsfHeader."Line Count By Creator", 'count() where(SystemCreatedBy = field("Owner Id"))');

        CfsfHeader."Owner Id" := CreateGuid();
        CfsfHeader.Modify(true);
        CfsfHeader.CalcFields("Line Count By Creator");
        Assert.AreEqual(0, CfsfHeader."Line Count By Creator", 'an Owner Id no line was created by must match nothing');
    end;

    /// TableRelation = "CFSF Line".SystemId — a relation whose target is a system field is
    /// enforced like any other.
    [Test]
    procedure Record_Validate_TableRelationOntoSystemId()
    var
        CfsfHeader: Record "CFSF Header";
        CfsfLine: Record "CFSF Line";
    begin
        Initialize(CfsfHeader);
        CfsfLine.Get(1);

        CfsfHeader.Validate("Line Sys Id", CfsfLine.SystemId);
        Assert.AreEqual(CfsfLine.SystemId, CfsfHeader."Line Sys Id", 'an existing line''s SystemId is accepted');

        asserterror CfsfHeader.Validate("Line Sys Id", CreateGuid());
        Assert.ExpectedError('cannot be found in the related table');
    end;
}
