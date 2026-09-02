// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: QFF Line (60974), QFF Header (60975), QFF Header FlowField (60979)
//
// A query column selecting a FlowField reads the FlowField's calculated value, the same
// value Record.CalcFields would compute for that row — not the field's raw/unset storage,
// and not zero when no source rows exist yet to sum.
codeunit 60987 "QFF Query FlowField Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        QffHeader: Record "QFF Header";
        QffLine: Record "QFF Line";
    begin
        QffLine.DeleteAll();
        QffHeader.DeleteAll();
    end;

    [Test]
    procedure FlowFieldColumn_ReadsCalculatedValue()
    var
        QffHeader: Record "QFF Header";
        QffLine: Record "QFF Line";
        Q: Query "QFF Header FlowField";
    begin
        Initialize();

        QffHeader.Init();
        QffHeader."No." := 'H1';
        QffHeader.Insert();

        QffLine.Init();
        QffLine."Entry No." := 1;
        QffLine."Header No." := 'H1';
        QffLine.Amount := 10.5;
        QffLine.Insert();

        QffLine.Init();
        QffLine."Entry No." := 2;
        QffLine."Header No." := 'H1';
        QffLine.Amount := 4.5;
        QffLine.Insert();

        Q.SetRange(No, 'H1');
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one matching header row');
        Assert.AreEqual(15, Q.TotalAmount, 'Query FlowField column must read the sum of matching QFF Line rows');
        Assert.IsFalse(Q.Read(), 'Query must only return one row');
        Q.Close();
    end;

    [Test]
    procedure FlowFieldColumn_NoMatchingSourceRows_ReadsZero()
    var
        QffHeader: Record "QFF Header";
        Q: Query "QFF Header FlowField";
    begin
        Initialize();

        QffHeader.Init();
        QffHeader."No." := 'H2';
        QffHeader.Insert();

        Q.SetRange(No, 'H2');
        Q.Open();

        Assert.IsTrue(Q.Read(), 'Query must return the one matching header row');
        Assert.AreEqual(0, Q.TotalAmount, 'Query FlowField column with no matching source rows must read 0, not fail');
        Q.Close();
    end;
}
