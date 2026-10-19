// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 81860
// Probe: corpus issue 673 item 2 (al-runtime-rs #293). The counters are not deterministic: only properties are observed (sign of a difference, equal or not), never a count. Asserted only where every CI run on BC 27.5, 28.5 and 29.0 gave the same answer.
// Facts: SessionInformation.SqlStatementsExecuted() and SqlRowsRead(): not negative; two reads with nothing between them; the change after Get, FindSet, Insert, Modify, Delete and Count on a table and on a temporary record; the type read through a Variant.
// BC versions: 27+

table 81860 "LT BL Sql Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 81861 "LT BL Sql Counters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        StmtBefore: BigInteger;
        RowsBefore: BigInteger;

    local procedure Seed()
    var
        Row: Record "LT BL Sql Row";
        I: Integer;
    begin
        Row.DeleteAll();
        for I := 1 to 3 do begin
            Row.Id := I;
            Row.Name := 'row ' + Format(I);
            Row.Insert();
        end;
        Commit();
    end;

    local procedure Mark()
    begin
        StmtBefore := SessionInformation.SqlStatementsExecuted();
        RowsBefore := SessionInformation.SqlRowsRead();
    end;

    local procedure Sign(Delta: BigInteger): Text
    begin
        if Delta > 0 then
            exit('increased');
        if Delta < 0 then
            exit('decreased');
        exit('same');
    end;

    local procedure Note(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Stmt: BigInteger;
        Rows: BigInteger;
    begin
        Stmt := SessionInformation.SqlStatementsExecuted();
        Rows := SessionInformation.SqlRowsRead();
        Observer.Observe(Name, 'statements ' + Sign(Stmt - StmtBefore) + ', rows ' + Sign(Rows - RowsBefore));
    end;

    // The al-runtime-rs #293 repro, and the sign of both counters.
    [Test]
    procedure Counters_NotNegative()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('statements >= 0', Format(SessionInformation.SqlStatementsExecuted() >= 0));
        Observer.Observe('rows >= 0', Format(SessionInformation.SqlRowsRead() >= 0));
        Observer.Finish();
    end;

    [Test]
    procedure Counters_Type()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        V := SessionInformation.SqlStatementsExecuted();
        Observer.Observe('statements isbiginteger', Format(V.IsBigInteger()));
        Observer.Observe('statements isinteger', Format(V.IsInteger()));
        V := SessionInformation.SqlRowsRead();
        Observer.Observe('rows isbiginteger', Format(V.IsBigInteger()));
        Observer.Observe('rows isinteger', Format(V.IsInteger()));
        Observer.Finish();
    end;

    [Test]
    procedure Counters_NothingBetween()
    var
        Observer: Codeunit "Probe Observer";
        X: Integer;
    begin
        Mark();
        Note(Observer, 'two reads');
        Mark();
        X := 1 + 2;
        Note(Observer, 'arithmetic only');
        Observer.Finish();
    end;

    [Test]
    procedure Counters_TableOperations()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Sql Row";
        N: Integer;
    begin
        Seed();
        Mark();
        Row.Get(2);
        Note(Observer, 'get');
        Mark();
        Row.FindSet();
        repeat
        until Row.Next() = 0;
        Note(Observer, 'findset loop');
        Mark();
        N := Row.Count();
        Note(Observer, 'count');
        Mark();
        Row.Id := 10;
        Row.Name := 'ten';
        Row.Insert();
        Note(Observer, 'insert');
        Mark();
        Row.Name := 'TEN';
        Row.Modify();
        Note(Observer, 'modify');
        Mark();
        Row.Delete();
        Note(Observer, 'delete');
        Observer.Finish();
    end;

    [Test]
    procedure Counters_TemporaryOperations()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT BL Sql Row" temporary;
        N: Integer;
    begin
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Mark();
        Row.Get(2);
        Note(Observer, 'get');
        Mark();
        Row.FindSet();
        repeat
        until Row.Next() = 0;
        Note(Observer, 'findset loop');
        Mark();
        N := Row.Count();
        Note(Observer, 'count');
        Mark();
        Row.Id := 10;
        Row.Insert();
        Note(Observer, 'insert');
        Mark();
        Row.Name := 'TEN';
        Row.Modify();
        Note(Observer, 'modify');
        Mark();
        Row.Delete();
        Note(Observer, 'delete');
        Observer.Finish();
    end;
}
