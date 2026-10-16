// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares tables 74054, 74055, queries 74056-74061
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a nested dataitem that is outer-joined (no SqlJoinType at all, and LeftOuterJoin spelled out) and carries a static filter: a Count column with ColumnFilter = const(0) or > 0 over the outer item (parents with no child), a plain column with a ColumnFilter, a DataItemTableFilter on an item with the default join type; two-field DataItemLink
// BC versions: 29 (27 and 28 by CI)

table 74054 "LT P133 Parent"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; DocNo; Code[20]) { }
        field(2; PostDate; Date) { }
        field(3; Amount; Decimal) { }
        field(4; Debit; Decimal) { }
    }

    keys
    {
        key(PK; DocNo, PostDate) { Clustered = true; }
    }
}

table 74055 "LT P133 Child"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; EntryNo; Integer) { }
        field(2; DocNo; Code[20]) { }
        field(3; PostDate; Date) { }
        field(4; Kind; Integer) { }
    }

    keys
    {
        key(PK; EntryNo) { Clustered = true; }
    }
}

query 74056 "LT P133 Q CountZero Default"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            column(SumAmount; Amount) { Method = Sum; }
            column(SumDebit; Debit) { Method = Sum; }
            column(NoOfParents) { Method = Count; }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                column(NoOfChildren)
                {
                    ColumnFilter = NoOfChildren = const(0);
                    Method = Count;
                }
            }
        }
    }
}

query 74057 "LT P133 Q CountZero Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            column(SumAmount; Amount) { Method = Sum; }
            column(NoOfParents) { Method = Count; }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(NoOfChildren)
                {
                    ColumnFilter = NoOfChildren = const(0);
                    Method = Count;
                }
            }
        }
    }
}

query 74058 "LT P133 Q CountPositive Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            column(NoOfParents) { Method = Count; }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(NoOfChildren)
                {
                    ColumnFilter = NoOfChildren = filter(> 0);
                    Method = Count;
                }
            }
        }
    }
}

query 74059 "LT P133 Q TableFilter Default"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo), ascending(EntryNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                DataItemTableFilter = Kind = const(1);
                column(EntryNo; EntryNo) { }
                column(Kind; Kind) { }
            }
        }
    }
}

query 74060 "LT P133 Q ColumnFilter Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo), ascending(EntryNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                column(EntryNo; EntryNo) { }
                column(Kind; Kind)
                {
                    ColumnFilter = Kind = const(1);
                }
            }
        }
    }
}

query 74061 "LT P133 Q TableFilter Left"
{
    QueryType = Normal;
    OrderBy = ascending(DocNo), ascending(EntryNo);

    elements
    {
        dataitem(Parent; "LT P133 Parent")
        {
            column(DocNo; DocNo) { }
            column(PostDate; PostDate) { }
            dataitem(Child; "LT P133 Child")
            {
                DataItemLink = DocNo = Parent.DocNo, PostDate = Parent.PostDate;
                SqlJoinType = LeftOuterJoin;
                DataItemTableFilter = Kind = const(1);
                column(EntryNo; EntryNo) { }
                column(Kind; Kind) { }
            }
        }
    }
}

codeunit 74062 "LT P133 Query Outer Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Parent: Record "LT P133 Parent";
        Child: Record "LT P133 Child";
    begin
        Parent.DeleteAll();
        Child.DeleteAll();
        // D1: two children (kinds 1 and 2); D2: one child (kind 2); D3: none; D4: one child with another date (no link match)
        InsertParent('D1', DMY2Date(1, 1, 2024), 10, 1);
        InsertParent('D2', DMY2Date(1, 1, 2024), 20, 2);
        InsertParent('D3', DMY2Date(1, 1, 2024), 30, 3);
        InsertParent('D4', DMY2Date(1, 1, 2024), 40, 4);
        InsertChild(1, 'D1', DMY2Date(1, 1, 2024), 1);
        InsertChild(2, 'D1', DMY2Date(1, 1, 2024), 2);
        InsertChild(3, 'D2', DMY2Date(1, 1, 2024), 2);
        InsertChild(4, 'D4', DMY2Date(2, 1, 2024), 1);
    end;

    local procedure InsertParent(DocNo: Code[20]; PostDate: Date; Amount: Decimal; Debit: Decimal)
    var
        Parent: Record "LT P133 Parent";
    begin
        Parent.DocNo := DocNo;
        Parent.PostDate := PostDate;
        Parent.Amount := Amount;
        Parent.Debit := Debit;
        Parent.Insert();
    end;

    local procedure InsertChild(EntryNo: Integer; DocNo: Code[20]; PostDate: Date; Kind: Integer)
    var
        Child: Record "LT P133 Child";
    begin
        Child.EntryNo := EntryNo;
        Child.DocNo := DocNo;
        Child.PostDate := PostDate;
        Child.Kind := Kind;
        Child.Insert();
    end;

    [TryFunction]
    local procedure TryDrainCountZeroDefault(var Result: Text)
    var
        Q: Query "LT P133 Q CountZero Default";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':parents=' + Format(Q.NoOfParents) + ',children=' + Format(Q.NoOfChildren) + ',amount=' + Format(Q.SumAmount, 0, 9) + ',debit=' + Format(Q.SumDebit, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainCountZeroLeft(var Result: Text)
    var
        Q: Query "LT P133 Q CountZero Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':parents=' + Format(Q.NoOfParents) + ',children=' + Format(Q.NoOfChildren) + ',amount=' + Format(Q.SumAmount, 0, 9) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainCountPositiveLeft(var Result: Text)
    var
        Q: Query "LT P133 Q CountPositive Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':parents=' + Format(Q.NoOfParents) + ',children=' + Format(Q.NoOfChildren) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainTableFilterDefault(var Result: Text)
    var
        Q: Query "LT P133 Q TableFilter Default";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':entry=' + Format(Q.EntryNo) + ',kind=' + Format(Q.Kind) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainColumnFilterLeft(var Result: Text)
    var
        Q: Query "LT P133 Q ColumnFilter Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':entry=' + Format(Q.EntryNo) + ',kind=' + Format(Q.Kind) + ' ';
    end;

    [TryFunction]
    local procedure TryDrainTableFilterLeft(var Result: Text)
    var
        Q: Query "LT P133 Q TableFilter Left";
    begin
        Q.Open();
        while Q.Read() do
            Result += Q.DocNo + ':entry=' + Format(Q.EntryNo) + ',kind=' + Format(Q.Kind) + ' ';
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Rows: Text)
    begin
        if Ok then
            Observer.Observe(Name, Rows)
        else begin
            Observer.Observe(Name, 'err ' + GetLastErrorText());
            ClearLastError();
        end;
    end;

    [Test]
    procedure P133_Query_CountColumnFilterZero_OverTheOuterItem()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Show(Observer, 'default join', TryDrainCountZeroDefault(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join', TryDrainCountZeroLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, filter > 0', TryDrainCountPositiveLeft(Rows), Rows);
        Observer.Expect('default join', 'D3:parents=1,children=0,amount=30,debit=3 D4:parents=1,children=0,amount=40,debit=4 ');
        Observer.Expect('left outer join', 'D3:parents=1,children=0,amount=30 D4:parents=1,children=0,amount=40 ');
        Observer.Expect('left outer join, filter > 0', 'D1:parents=2,children=2 D2:parents=1,children=1 ');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Query_StaticFiltersOnTheOuterItem_TableAndColumn()
    var
        Observer: Codeunit "Probe Observer";
        Rows: Text;
    begin
        Seed();
        Show(Observer, 'default join, table filter kind 1', TryDrainTableFilterDefault(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, table filter kind 1', TryDrainTableFilterLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, column filter kind 1', TryDrainColumnFilterLeft(Rows), Rows);
        Observer.Expect('default join, table filter kind 1', 'D1:entry=1,kind=1 ');
        Observer.Expect('left outer join, table filter kind 1', 'D1:entry=1,kind=1 ');
        Observer.Expect('left outer join, column filter kind 1', 'D1:entry=1,kind=1 ');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Query_CountZero_NoChildrenAtAll()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "LT P133 Child";
        Rows: Text;
    begin
        Seed();
        Child.DeleteAll();
        Show(Observer, 'default join, no children', TryDrainCountZeroDefault(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, no children', TryDrainCountZeroLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'left outer join, filter > 0, no children', TryDrainCountPositiveLeft(Rows), Rows);
        Clear(Rows);
        Show(Observer, 'default join, table filter, no children', TryDrainTableFilterDefault(Rows), Rows);
        Observer.Expect('default join, no children', 'D1:parents=1,children=0,amount=10,debit=1 D2:parents=1,children=0,amount=20,debit=2 D3:parents=1,children=0,amount=30,debit=3 D4:parents=1,children=0,amount=40,debit=4 ');
        Observer.Expect('left outer join, no children', 'D1:parents=1,children=0,amount=10 D2:parents=1,children=0,amount=20 D3:parents=1,children=0,amount=30 D4:parents=1,children=0,amount=40 ');
        Observer.Expect('left outer join, filter > 0, no children', '');
        Observer.Expect('default join, table filter, no children', '');
        Observer.Verify();
    end;
}
