// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Universal Query (60022)

codeunit 60205 "Test Query Object"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        UniversalQuery: Query "ALT Universal Query";

    [Test]
    procedure Query_Open_Read_ReturnsInsertedRows()
    var
        RowCount: Integer;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.Open();
        RowCount := 0;

        Assert.IsTrue(UniversalQuery.Read(), 'Query must return the first inserted row');
        RowCount += 1;
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'First query row must be entry 1');
        Assert.AreEqual(10, UniversalQuery.IntegerValue, 'First query row must expose the integer field value');
        Assert.AreEqual('First', UniversalQuery.TextValue, 'First query row must expose the text field value');

        Assert.IsTrue(UniversalQuery.Read(), 'Query must return the second inserted row');
        RowCount += 1;
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Second query row must be entry 2');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'Second query row must expose the integer field value');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Second query row must expose the text field value');

        Assert.IsFalse(UniversalQuery.Read(), 'Query must stop after the inserted rows');
        UniversalQuery.Close();

        Assert.AreEqual(2, RowCount, 'Query must return both inserted rows');
    end;

    [Test]
    procedure Query_SetRange_FiltersToMatchingRow()
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'Filtered query must return the matching row');
        Assert.AreEqual(2, UniversalQuery.EntryNo, 'Filtered query row must be entry 2');
        Assert.AreEqual(20, UniversalQuery.IntegerValue, 'Filtered query row must keep its integer value');
        Assert.AreEqual('Second', UniversalQuery.TextValue, 'Filtered query row must keep its text value');
        Assert.IsFalse(UniversalQuery.Read(), 'Filtered query must only return one row');
        UniversalQuery.Close();
    end;

    [Test]
    procedure Query_GetFilter_AfterSetRange_ReturnsFilterText()
    var
        FilterText: Text;
    begin
        Initialize();
        InsertQueryRows();

        UniversalQuery.SetRange(EntryNo, 2);
        FilterText := UniversalQuery.GetFilter(EntryNo);

        Assert.AreEqual('2', FilterText, 'Query.GetFilter must return the value applied by SetRange');
    end;

    [Test]
    procedure Query_TopNumberOfRows_LimitsResultSet()
    begin
        Initialize();
        InsertQueryRows();

        Assert.AreEqual(1, UniversalQuery.TopNumberOfRows(), 'Query fixture must be configured to return one row');
        UniversalQuery.Open();

        Assert.IsTrue(UniversalQuery.Read(), 'TopNumberOfRows must still return the first row');
        Assert.AreEqual(1, UniversalQuery.EntryNo, 'TopNumberOfRows must keep the first row only');
        Assert.IsFalse(UniversalQuery.Read(), 'TopNumberOfRows must limit the dataset to one row');
        UniversalQuery.Close();
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure InsertQueryRows()
    var
        Rec: Record "ALT Universal";
    begin
        InsertQueryRow(Rec, 1, 10, 'First');
        InsertQueryRow(Rec, 2, 20, 'Second');
    end;

    local procedure InsertQueryRow(var Rec: Record "ALT Universal"; EntryNo: Integer; IntegerValue: Integer; TextValue: Text)
    begin
        Rec.Init();
        Rec."Entry No." := EntryNo;
        Rec."Integer Field" := IntegerValue;
        Rec."Text Field" := TextValue;
        Rec.Insert();
    end;
}
