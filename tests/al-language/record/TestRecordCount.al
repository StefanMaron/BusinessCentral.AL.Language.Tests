// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-count-method
// Scope: in-scope
// Fixtures used: ALT Universal (60000)

codeunit 60063 "Test Record Count"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Record_Count_EmptyTable_ReturnsZero()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.AreEqual(0, Rec.Count(), 'Count() must be 0 on an empty table after Initialize()');
    end;

    [Test]
    procedure Record_Count_ThreeRecords_ReturnsThree()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Assert.AreEqual(3, Rec.Count(), 'Count() must return 3 after inserting 3 records');
    end;

    [Test]
    procedure Record_Count_WithFilter_CountsFiltered()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 5 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Rec.SetRange("Entry No.", 1, 3);
        Assert.AreEqual(3, Rec.Count(), 'Count() with SetRange(1,3) must return 3 on 5-record table');
    end;

    [Test]
    procedure Record_CountApprox_ReturnsNonNegativeInteger()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec.Insert();
        Assert.IsTrue(Rec.CountApprox() >= 0, 'CountApprox() must return non-negative integer');
        Assert.IsTrue(Rec.CountApprox() > 0, 'CountApprox() with 2 records must return > 0');
    end;

    [Test]
    procedure Record_CountApprox_ApproximatesActualCount()
    var
        Rec: Record "ALT Universal";
        i: Integer;
    begin
        Initialize();
        for i := 1 to 10 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        Assert.IsTrue(Rec.CountApprox() > 0, 'CountApprox() with 10 records must return > 0 (not always 0)');
    end;

    [Test]
    procedure Record_IsEmpty_EmptyTable_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Assert.IsTrue(Rec.IsEmpty(), 'IsEmpty() must return true on empty table after Initialize()');
    end;

    [Test]
    procedure Record_IsEmpty_NonEmptyTable_ReturnsFalse()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Assert.IsFalse(Rec.IsEmpty(), 'IsEmpty() must return false after inserting 1 record');
    end;

    [Test]
    procedure Record_IsEmpty_WithFilter_EmptyFilter_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec.SetRange("Entry No.", 999);
        Assert.IsTrue(Rec.IsEmpty(), 'IsEmpty() with non-matching filter SetRange(999) must return true');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
