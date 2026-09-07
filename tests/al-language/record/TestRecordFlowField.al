// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: ALT Parent (60004), ALT Child (60005), ALT Universal (60000)

codeunit 60058 "Test Record FlowField"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_CalcFields_CountFlowField_ReturnsChildCount()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        AltParent."Entry No." := 1;
        AltParent.Insert();

        AltChild."Entry No." := 1;
        AltChild."Parent Entry No." := 1;
        AltChild.Insert();

        AltChild."Entry No." := 2;
        AltChild."Parent Entry No." := 1;
        AltChild.Insert();

        AltParent.Get(1);
        AltParent.CalcFields("Child Count");
        Assert.AreEqual(2, AltParent."Child Count", 'Child Count FlowField must equal number of children');
    end;

    [Test]
    procedure Record_CalcFields_SumFlowField_ReturnsSumOfChildren()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        AltParent."Entry No." := 2;
        AltParent.Insert();

        AltChild."Entry No." := 10;
        AltChild."Parent Entry No." := 2;
        AltChild."Amount" := 100;
        AltChild.Insert();

        AltChild."Entry No." := 11;
        AltChild."Parent Entry No." := 2;
        AltChild."Amount" := 50;
        AltChild.Insert();

        AltParent.Get(2);
        AltParent.CalcFields("Child Amount");
        Assert.AreEqual(150, AltParent."Child Amount", 'Child Amount FlowField must sum children');
    end;

    [Test]
    procedure Record_CalcFields_LookupFlowField_ReturnsFirstChildCode()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        AltParent."Entry No." := 3;
        AltParent.Insert();

        AltChild."Entry No." := 20;
        AltChild."Parent Entry No." := 3;
        AltChild."Code" := 'FIRST';
        AltChild.Insert();

        AltParent.Get(3);
        AltParent.CalcFields("First Child Code");
        Assert.AreEqual('FIRST', AltParent."First Child Code", 'First Child Code FlowField must return code of first child');
    end;

    [Test]
    procedure Record_CalcFields_MultipleFields_AllCalculated()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        AltParent."Entry No." := 4;
        AltParent.Insert();

        AltChild."Entry No." := 30;
        AltChild."Parent Entry No." := 4;
        AltChild."Amount" := 25;
        AltChild.Insert();

        AltChild."Entry No." := 31;
        AltChild."Parent Entry No." := 4;
        AltChild."Amount" := 25;
        AltChild.Insert();

        AltParent.Get(4);
        AltParent.CalcFields("Child Count", "Child Amount");
        Assert.AreEqual(2, AltParent."Child Count", 'Child Count must be calculated');
        Assert.AreEqual(50, AltParent."Child Amount", 'Child Amount must be calculated');
    end;

    [Test]
    procedure Record_CalcFields_NoChildren_CountIsZero()
    var
        AltParent: Record "ALT Parent";
    begin
        Initialize();
        AltParent."Entry No." := 5;
        AltParent.Insert();

        AltParent.Get(5);
        AltParent.CalcFields("Child Count");
        Assert.AreEqual(0, AltParent."Child Count", 'Child Count must be 0 with no children');
    end;

    [Test]
    procedure Record_CalcSums_SingleDecimalField_ReturnsTotalSum()
    var
        AltUniversal: Record "ALT Universal";
    begin
        Initialize();
        AltUniversal."Entry No." := 100;
        AltUniversal."Amount Field" := 40;
        AltUniversal.Insert();

        AltUniversal."Entry No." := 101;
        AltUniversal."Amount Field" := 60;
        AltUniversal.Insert();

        AltUniversal.SetRange("Entry No.", 100, 101);
        AltUniversal.CalcSums("Amount Field");
        Assert.AreEqual(100, AltUniversal."Amount Field", 'CalcSums must return total of all Amount Field values');
    end;

    [Test]
    procedure Record_CalcSums_WithFilter_SumsOnlyMatching()
    var
        AltUniversal: Record "ALT Universal";
    begin
        Initialize();
        AltUniversal."Entry No." := 200;
        AltUniversal."Amount Field" := 10;
        AltUniversal.Insert();

        AltUniversal."Entry No." := 201;
        AltUniversal."Amount Field" := 20;
        AltUniversal.Insert();

        AltUniversal."Entry No." := 202;
        AltUniversal."Amount Field" := 30;
        AltUniversal.Insert();

        AltUniversal.SetRange("Entry No.", 200, 201);
        AltUniversal.CalcSums("Amount Field");
        Assert.AreEqual(30, AltUniversal."Amount Field", 'CalcSums with filter must sum only matching records');
    end;

    [Test]
    procedure Record_CalcSums_MultipleFields_BothSummed()
    var
        AltUniversal: Record "ALT Universal";
    begin
        Initialize();
        AltUniversal."Entry No." := 300;
        AltUniversal."Amount Field" := 15;
        AltUniversal."Decimal Field" := 25;
        AltUniversal.Insert();

        AltUniversal."Entry No." := 301;
        AltUniversal."Amount Field" := 35;
        AltUniversal."Decimal Field" := 45;
        AltUniversal.Insert();

        AltUniversal.SetRange("Entry No.", 300, 301);
        AltUniversal.CalcSums("Amount Field", "Decimal Field");
        Assert.AreEqual(50, AltUniversal."Amount Field", 'Amount Field must be summed');
        Assert.AreEqual(70, AltUniversal."Decimal Field", 'Decimal Field must be summed');
    end;

    [Test]
    procedure Record_SetAutoCalcFields_AfterSet_FindFirstAutoCalculates()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        AltParent."Entry No." := 6;
        AltParent.Insert();

        AltChild."Entry No." := 40;
        AltChild."Parent Entry No." := 6;
        AltChild.Insert();

        AltChild."Entry No." := 41;
        AltChild."Parent Entry No." := 6;
        AltChild.Insert();

        AltParent.SetAutoCalcFields("Child Count");
        AltParent.FindFirst();
        Assert.AreEqual(2, AltParent."Child Count", 'SetAutoCalcFields must auto-calc on FindFirst');
    end;

    [Test]
    procedure Record_SetAutoCalcFields_MultipleFields_AllAutoCalculated()
    var
        AltParent: Record "ALT Parent";
        AltChild: Record "ALT Child";
    begin
        Initialize();
        AltParent."Entry No." := 7;
        AltParent.Insert();

        AltChild."Entry No." := 50;
        AltChild."Parent Entry No." := 7;
        AltChild."Amount" := 80;
        AltChild.Insert();

        AltParent.SetAutoCalcFields("Child Count", "Child Amount");
        AltParent.FindFirst();
        Assert.AreEqual(1, AltParent."Child Count", 'Child Count must be auto-calculated');
        Assert.AreEqual(80, AltParent."Child Amount", 'Child Amount must be auto-calculated');
    end;

    [Test]
    procedure Record_LoadFields_FieldsAreAvailable()
    var
        AltUniversal: Record "ALT Universal";
    begin
        Initialize();
        AltUniversal."Entry No." := 400;
        AltUniversal."Integer Field" := 42;
        AltUniversal.Insert();

        AltUniversal.SetLoadFields(AltUniversal."Integer Field");
        AltUniversal.Get(400);
        Assert.AreEqual(42, AltUniversal."Integer Field", 'LoadFields must make field available');
    end;

    [Test]
    procedure Record_AreFieldsLoaded_ReturnsTrueWhenLoaded()
    var
        AltUniversal: Record "ALT Universal";
        IsLoaded: Boolean;
    begin
        Initialize();
        AltUniversal."Entry No." := 401;
        AltUniversal."Integer Field" := 55;
        AltUniversal.Insert();

        AltUniversal.SetLoadFields(AltUniversal."Integer Field");
        AltUniversal.Get(401);
        IsLoaded := AltUniversal.AreFieldsLoaded(AltUniversal."Integer Field");
        Assert.IsTrue(IsLoaded, 'AreFieldsLoaded must return true for loaded Integer Field');
    end;

    [Test]
    procedure Record_SetLoadFields_LimitsLoadedFields()
    var
        AltUniversal: Record "ALT Universal";
    begin
        Initialize();
        AltUniversal."Entry No." := 402;
        AltUniversal."Integer Field" := 99;
        AltUniversal."Text Field" := 'hello';
        AltUniversal.Insert();

        AltUniversal.SetLoadFields(AltUniversal."Integer Field");
        AltUniversal.Get(402);
        Assert.AreEqual(99, AltUniversal."Integer Field", 'SetLoadFields must load the specified field');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
