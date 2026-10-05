// A table's unqualified TableRelation or CalcFormula table name is resolved by the compiler in
// the scope of the file that wrote it: its own namespace first, then its using directives. This
// file pins the case where the name is found in BOTH the file's own namespace and an imported
// one, and one of the two is a Base Application table while the other is declared in this app.
//
// ALTRelationOwnDepImportedTables.al declares "Shipment Method" (69220) and "Shipping Agent"
// (69221) in ALLanguage.Coverage.RelationOwnDepImported. Base Application declares tables of the
// same names, 10 and 291, in Microsoft.Foundation.Shipping.
//
// - 69222 and 69223 are written in Microsoft.Foundation.Shipping and import the app's namespace:
//   the own-namespace table is Base Application's, so the names mean tables 10 and 291 and the
//   imported app tables never take over.
// - 69226 and 69227 are written in the app's namespace and import Microsoft.Foundation.Shipping:
//   the own-namespace tables are the app's, so the names mean 69220 and 69221. This is the
//   other direction of the same rule.
// - 69223 and 69227 are each extended by a tableextension whose modify(...) changes the relation
//   field; 69222 and 69226 are not. Same names, same expected answers. Table extension 69224
//   also adds a field, "Ext Method Code", written in the same file as table 69223.
//
// Each test asserts a concrete id or count. The Validate tests also assert the OTHER table is
// refused, and each FlowField test fills the two tables with different row counts.

codeunit 69217 "Test Relation Own NS Dep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure RelationOwnNS_OwnDep_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69222);

        Assert.AreEqual(10, RecRef.Field(2).Relation(),
            'the unqualified "Shipment Method" in table 69222 relates to Base Application table 10 (the own-namespace table), not the imported 69220');
    end;

    [Test]
    procedure RelationOwnNS_OwnDep_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertMethods();

        RecRef.Open(69222);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(2).Value),
            'a value present only in Base Application table 10 validates');

        asserterror RecRef.Field(2).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnDep_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertAgents('ALTAG69222');

        RecRef.Open(69222);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTAG69222';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(1, RecRef.Field(3).Value,
            'the FlowField in table 69222 counts Base Application "Shipping Agent" (1 row), not the imported 69221 (2 rows)');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepMod_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69223);

        Assert.AreEqual(10, RecRef.Field(2).Relation(),
            'the unqualified "Shipment Method" in table 69223 relates to Base Application table 10 (the own-namespace table), not the imported 69220');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepMod_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertMethods();

        RecRef.Open(69223);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(2).Value),
            'a value present only in Base Application table 10 validates');

        asserterror RecRef.Field(2).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepMod_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertAgents('ALTAG69223');

        RecRef.Open(69223);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTAG69223';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(1, RecRef.Field(3).Value,
            'the FlowField in table 69223 counts Base Application "Shipping Agent" (1 row), not the imported 69221 (2 rows)');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundle_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69226);

        Assert.AreEqual(69220, RecRef.Field(2).Relation(),
            'the unqualified "Shipment Method" in table 69226 relates to the same-namespace table 69220, not Base Application table 10 that the using brings in');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundle_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertMethods();

        RecRef.Open(69226);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-namespace table 69220 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundle_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertAgents('ALTAG69226');

        RecRef.Open(69226);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTAG69226';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69226 counts the same-namespace "Shipping Agent" 69221 (2 rows), not the imported Base Application one (1 row)');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundleMod_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69227);

        Assert.AreEqual(69220, RecRef.Field(2).Relation(),
            'the unqualified "Shipment Method" in table 69227 relates to the same-namespace table 69220, not Base Application table 10 that the using brings in');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundleMod_Validate_AcceptsOwnNamespaceRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertMethods();

        RecRef.Open(69227);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(2).Validate('ALTLOCAL');
        Assert.AreEqual('ALTLOCAL', Format(RecRef.Field(2).Value),
            'a value present only in the same-namespace table 69220 validates');

        asserterror RecRef.Field(2).Validate('ALTBASE');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure RelationOwnNS_OwnBundleMod_FlowField_CountsTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        InsertAgents('ALTAG69227');

        RecRef.Open(69227);
        RecRef.Init();
        RecRef.Field(1).Value := 'ALTAG69227';
        RecRef.Field(3).CalcField();

        Assert.AreEqual(2, RecRef.Field(3).Value,
            'the FlowField in table 69227 counts the same-namespace "Shipping Agent" 69221 (2 rows), not the imported Base Application one (1 row)');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepMod_ExtensionField_RelationAnswersTheOwnNamespaceTable()
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(69223);

        Assert.AreEqual(10, RecRef.Field(69225).Relation(),
            'the extension field is written in the file of table 69223, where "Shipment Method" means Base Application table 10, not the imported 69220');
    end;

    [Test]
    procedure RelationOwnNS_OwnDepMod_ExtensionField_Validate_AcceptsBaseRefusesImported()
    var
        RecRef: RecordRef;
    begin
        InsertMethods();

        RecRef.Open(69223);
        RecRef.Init();
        RecRef.Field(1).Value := 'A';
        RecRef.Field(69225).Validate('ALTBASE');
        Assert.AreEqual('ALTBASE', Format(RecRef.Field(69225).Value),
            'a value present only in Base Application table 10 validates');

        asserterror RecRef.Field(69225).Validate('ALTLOCAL');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    local procedure InsertMethods()
    var
        BaseMethod: Record Microsoft.Foundation.Shipping."Shipment Method";
        LocalMethod: Record ALLanguage.Coverage.RelationOwnDepImported."Shipment Method";
    begin
        if not BaseMethod.Get('ALTBASE') then begin
            BaseMethod.Init();
            BaseMethod.Code := 'ALTBASE';
            BaseMethod.Insert(false);
        end;
        if not LocalMethod.Get('ALTLOCAL') then begin
            LocalMethod.Init();
            LocalMethod.Code := 'ALTLOCAL';
            LocalMethod.Insert(false);
        end;
    end;

    // Base Application's "Shipping Agent" gets one row for the code, the same-named app table
    // gets two.
    local procedure InsertAgents(AgentCode: Code[10])
    var
        BaseAgent: Record Microsoft.Foundation.Shipping."Shipping Agent";
        LocalAgent: Record ALLanguage.Coverage.RelationOwnDepImported."Shipping Agent";
    begin
        BaseAgent.Init();
        BaseAgent.Code := AgentCode;
        BaseAgent.Insert(false);

        LocalAgent.Init();
        LocalAgent.Code := AgentCode;
        LocalAgent.Seq := 1;
        LocalAgent.Insert(false);
        LocalAgent.Init();
        LocalAgent.Code := AgentCode;
        LocalAgent.Seq := 2;
        LocalAgent.Insert(false);
    end;
}
