// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setautocalcfields-method
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005)
//
// SetAutoCalcFields applies to every read that retrieves a record, not only to
// FindFirst/FindSet/Next (covered by codeunit 60058). These tests pin the direct-lookup
// reads: Get by primary key, Get by RecordId, GetBySystemId, Find('=') and RecordRef.Get.

codeunit 60910 "Test SetAutoCalcFields On Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure SetAutoCalcFields_ThenGet_CalculatesCountAndSum()
    var
        AltParent: Record "ALT Parent";
    begin
        Initialize();
        CreateParentsWithChildren();

        AltParent.SetAutoCalcFields("Child Count", "Child Amount");
        AltParent.Get(1);
        Assert.AreEqual(2, AltParent."Child Count", 'Get after SetAutoCalcFields must calculate the Count FlowField');
        Assert.AreEqual(80, AltParent."Child Amount", 'Get after SetAutoCalcFields must calculate the Sum FlowField');
    end;

    [Test]
    procedure Get_WithoutSetAutoCalcFields_LeavesFlowFieldUncalculated()
    var
        AltParent: Record "ALT Parent";
    begin
        Initialize();
        CreateParentsWithChildren();

        AltParent.Get(1);
        Assert.AreEqual(0, AltParent."Child Count", 'Get without SetAutoCalcFields must not calculate the Count FlowField');
        Assert.AreEqual(0, AltParent."Child Amount", 'Get without SetAutoCalcFields must not calculate the Sum FlowField');
    end;

    [Test]
    procedure SetAutoCalcFields_ThenGet_RecalculatesOnEachGet()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        CreateParentsWithChildren();

        AltParent.SetAutoCalcFields("Child Count");
        AltParent.Get(2);
        Assert.AreEqual(1, AltParent."Child Count", 'first Get must see the one child of parent 2');

        AltChild."Entry No." := 20;
        AltChild."Parent Entry No." := 2;
        AltChild.Amount := 5;
        AltChild.Insert();

        AltParent.Get(2);
        Assert.AreEqual(2, AltParent."Child Count", 'second Get must recalculate and see the newly inserted child');
    end;

    [Test]
    procedure SetAutoCalcFields_ThenGetByRecordId_Calculates()
    var
        AltParent: Record "ALT Parent";
        Source: Record "ALT Parent";
    begin
        Initialize();
        CreateParentsWithChildren();
        Source.Get(1);

        AltParent.SetAutoCalcFields("Child Count");
        AltParent.Get(Source.RecordId);
        Assert.AreEqual(2, AltParent."Child Count", 'Get(RecordId) after SetAutoCalcFields must calculate the FlowField');
    end;

    [Test]
    procedure SetAutoCalcFields_ThenGetBySystemId_Calculates()
    var
        AltParent: Record "ALT Parent";
        Source: Record "ALT Parent";
    begin
        Initialize();
        CreateParentsWithChildren();
        Source.Get(1);

        AltParent.SetAutoCalcFields("Child Count");
        AltParent.GetBySystemId(Source.SystemId);
        Assert.AreEqual(2, AltParent."Child Count", 'GetBySystemId after SetAutoCalcFields must calculate the FlowField');
    end;

    [Test]
    procedure SetAutoCalcFields_ThenFindEquals_Calculates()
    var
        AltParent: Record "ALT Parent";
    begin
        Initialize();
        CreateParentsWithChildren();

        AltParent.SetAutoCalcFields("Child Count");
        AltParent."Entry No." := 1;
        Assert.IsTrue(AltParent.Find('='), 'Find(''='') must find parent 1');
        Assert.AreEqual(2, AltParent."Child Count", 'Find(''='') after SetAutoCalcFields must calculate the FlowField');
    end;

    [Test]
    procedure RecordRef_SetAutoCalcFields_ThenGet_Calculates()
    var
        Source: Record "ALT Parent";
        RecRef: RecordRef;
    begin
        Initialize();
        CreateParentsWithChildren();
        Source.Get(1);

        RecRef.Open(Database::"ALT Parent");
        RecRef.SetAutoCalcFields(Source.FieldNo("Child Count"));
        RecRef.Get(Source.RecordId);
        Assert.AreEqual(2, RecRef.Field(Source.FieldNo("Child Count")).Value, 'RecordRef.Get after SetAutoCalcFields must calculate the FlowField');
        RecRef.Close();
    end;

    local procedure CreateParentsWithChildren()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        AltParent."Entry No." := 1;
        AltParent.Insert();
        AltParent."Entry No." := 2;
        AltParent.Insert();

        AltChild."Entry No." := 10;
        AltChild."Parent Entry No." := 1;
        AltChild.Amount := 30;
        AltChild.Insert();

        AltChild."Entry No." := 11;
        AltChild."Parent Entry No." := 1;
        AltChild.Amount := 50;
        AltChild.Insert();

        AltChild."Entry No." := 12;
        AltChild."Parent Entry No." := 2;
        AltChild.Amount := 7;
        AltChild.Insert();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
