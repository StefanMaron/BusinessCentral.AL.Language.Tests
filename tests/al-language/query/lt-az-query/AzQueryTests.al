// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80660-80669 (AzQueryObjects.al)
// Probe: corpus issue 651 (queries and event subscribers), items 1, 3, 5, 7 and 8, writer AZ.
// Already pinned: items 2, 4 and 6 (query/lt-query-live-write, query/lt-query-read-to-end, query/PRQueryOpenColumn.al); Method = Count on a
// field column does not compile (must-not-compile case 0102).
// BC versions: 27, 28, 29

codeunit 80670 "LT AZ Query Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddRow(Id: Integer; Cat: Code[10]; Sub: Code[10]; Amount: Decimal; Kind: Code[10])
    var
        Row: Record "LT AZ Q Row";
    begin
        Row.Id := Id;
        Row.Cat := Cat;
        Row.Sub := Sub;
        Row.Amount := Amount;
        Row.Kind := Kind;
        Row.Insert();
    end;

    local procedure ReadTwoGroups(): Text
    var
        Q: Query "LT AZ Q Two Groups";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Cat + '/' + Q.Sub + '=' + Format(Q.Total) + ';';
        exit(R);
    end;

    local procedure ReadOneGroup(): Text
    var
        Q: Query "LT AZ Q One Group";
        R: Text;
    begin
        Q.Open();
        while Q.Read() do
            R += Q.Cat + '=' + Format(Q.Total) + '/' + Format(Q.N) + ';';
        exit(R);
    end;

    // ---- item 1: aggregated query without OrderBy, groups equal in the first group column ----

    [Test]
    procedure NoOrderBy_TwoGroupsSameCat()
    var
        Row: Record "LT AZ Q Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'A', 'Z', 1, '');
        AddRow(2, 'A', 'B', 2, '');
        AddRow(3, 'B', 'A', 4, '');
        AddRow(4, 'A', 'Z', 8, '');
        Observer.Observe('z_first', ReadTwoGroups());
        Row.DeleteAll();
        AddRow(1, 'A', 'B', 2, '');
        AddRow(2, 'A', 'Z', 1, '');
        AddRow(3, 'B', 'A', 4, '');
        Observer.Observe('b_first', ReadTwoGroups());
        Observer.Finish();
    end;

    [Test]
    procedure NoOrderBy_EqualSums()
    var
        Row: Record "LT AZ Q Row";
    begin
        Row.DeleteAll();
        AddRow(1, 'B', 'X', 5, '');
        AddRow(2, 'A', 'Y', 5, '');
        AddRow(3, 'C', 'X', 5, '');
        Observer.Observe('order', ReadOneGroup());
        Observer.Finish();
    end;

    // ---- item 3: Sum over a count FlowField, filtered and unfiltered ----

    local procedure SeedHeads()
    var
        Row: Record "LT AZ Q Row";
        Head: Record "LT AZ Q Head";
    begin
        Row.DeleteAll();
        Head.DeleteAll();
        Head.Cat := 'A';
        Head.Grp := 'G1';
        Head.Insert();
        Head.Cat := 'B';
        Head.Grp := 'G1';
        Head.Insert();
        Head.Cat := 'C';
        Head.Grp := 'G2';
        Head.Insert();
        AddRow(1, 'A', '', 1, 'K1');
        AddRow(2, 'A', '', 1, 'K1');
        AddRow(3, 'A', '', 1, 'K2');
        AddRow(4, 'B', '', 1, 'K2');
    end;

    local procedure ReadSumCount(KindFilter: Text): Text
    var
        Q: Query "LT AZ Q Sum Count FF";
        R: Text;
    begin
        if KindFilter <> '' then
            Q.SetFilter(KindFilter, KindFilter);
        Q.Open();
        while Q.Read() do
            R += Q.Grp + '=' + Format(Q.SumLines) + '/' + Format(Q.N) + ';';
        exit(R);
    end;

    local procedure ReadSumCountAll(KindFilter: Text; CatFilter: Text): Text
    var
        Q: Query "LT AZ Q Sum Count FF All";
        R: Text;
    begin
        if KindFilter <> '' then
            Q.SetFilter(KindFilter, KindFilter);
        if CatFilter <> '' then
            Q.SetFilter(CatFilter, CatFilter);
        Q.Open();
        while Q.Read() do
            R += Format(Q.SumLines) + ';';
        exit(R);
    end;

    local procedure PerRow(KindFilter: Text): Text
    var
        Head: Record "LT AZ Q Head";
        R: Text;
    begin
        if KindFilter <> '' then
            Head.SetFilter("Kind Filter", KindFilter);
        if Head.FindSet() then
            repeat
                Head.CalcFields(Lines);
                R += Head.Cat + '=' + Format(Head.Lines) + ';';
            until Head.Next() = 0;
        exit(R);
    end;

    [Test]
    procedure SumOverCountFlowField()
    begin
        SeedHeads();
        Observer.Observe('perrow', PerRow(''));
        Observer.Observe('perrow_k1', PerRow('K1'));
        Observer.Observe('grouped', ReadSumCount(''));
        Observer.Observe('grouped_k1', ReadSumCount('K1'));
        Observer.Observe('grouped_k2', ReadSumCount('K2'));
        Observer.Observe('all', ReadSumCountAll('', ''));
        Observer.Observe('all_k1', ReadSumCountAll('K1', ''));
        Observer.Observe('all_cat_a', ReadSumCountAll('', 'A'));
        Observer.Observe('all_cat_c', ReadSumCountAll('', 'C'));
        Observer.Finish();
    end;

    // ---- item 5: a RecordId column: grouping, OrderBy, SetFilter and SaveAsCsv ----

    local procedure SeedRefs(var HeadA: Record "LT AZ Q Head"; var HeadB: Record "LT AZ Q Head")
    var
        Row: Record "LT AZ Q Row";
    begin
        SeedHeads();
        HeadA.Get('A');
        HeadB.Get('B');
        Row.Get(1);
        Row.Ref := HeadA.RecordId;
        Row.Modify();
        Row.Get(2);
        Row.Ref := HeadB.RecordId;
        Row.Modify();
        Row.Get(3);
        Row.Ref := HeadA.RecordId;
        Row.Modify();
    end;

    [TryFunction]
    local procedure TryReadRidPlain(Filter: Text; var R: Text)
    var
        Q: Query "LT AZ Q Rid Plain";
    begin
        Q.SetFilter(Ref, Filter);
        Q.Open();
        while Q.Read() do
            R += Format(Q.Id) + ';';
    end;

    [Test]
    procedure RecordIdColumn_GroupAndOrderBy()
    var
        HeadA: Record "LT AZ Q Head";
        HeadB: Record "LT AZ Q Head";
        Q: Query "LT AZ Q Rid Group";
        R: Text;
    begin
        SeedRefs(HeadA, HeadB);
        Q.Open();
        while Q.Read() do
            R += Format(Q.Ref) + '=' + Format(Q.N) + ';';
        Observer.Observe('groups', R);
        Observer.Finish();
    end;

    [Test]
    procedure RecordIdColumn_SetFilter()
    var
        HeadA: Record "LT AZ Q Head";
        HeadB: Record "LT AZ Q Head";
        R: Text;
    begin
        SeedRefs(HeadA, HeadB);
        Observer.Observe('format_a', Format(HeadA.RecordId));
        R := '';
        Observer.Observe('eq_ok', Format(TryReadRidPlain(Format(HeadA.RecordId), R)));
        Observer.Observe('eq_rows', R);
        Observer.ObserveError('eq');
        R := '';
        Observer.Observe('quoted_ok', Format(TryReadRidPlain('''' + Format(HeadA.RecordId) + '''', R)));
        Observer.Observe('quoted_rows', R);
        Observer.ObserveError('quoted');
        R := '';
        Observer.Observe('blank_ok', Format(TryReadRidPlain('''''', R)));
        Observer.Observe('blank_rows', R);
        Observer.ObserveError('blank');
        R := '';
        Observer.Observe('notblank_ok', Format(TryReadRidPlain('<>''''', R)));
        Observer.Observe('notblank_rows', R);
        Observer.ObserveError('notblank');
        R := '';
        Observer.Observe('text_ok', Format(TryReadRidPlain('abc', R)));
        Observer.Observe('text_rows', R);
        Observer.ObserveError('text');
        Observer.Finish();
    end;

    [Test]
    procedure RecordIdColumn_SaveAsCsv()
    var
        HeadA: Record "LT AZ Q Head";
        HeadB: Record "LT AZ Q Head";
        TempBlob: Codeunit "Temp Blob";
        Q: Query "LT AZ Q Rid Plain";
        Out: OutStream;
        Ins: InStream;
        Line: Text;
        R: Text;
    begin
        SeedRefs(HeadA, HeadB);
        TempBlob.CreateOutStream(Out);
        Observer.Observe('save', Format(Q.SaveAsCsv(Out)));
        TempBlob.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.ReadText(Line);
            R += Line + '|';
        end;
        Observer.Observe('csv', R);
        Observer.Finish();
    end;

    // ---- item 7: a query procedure that reads a filter element by its bare name ----

    [TryFunction]
    local procedure TryReadKindF(var Q: Query "LT AZ Q Filter Proc"; var R: Text)
    begin
        R := Q.ReadKindF();
    end;

    local procedure ObserveKindF(var Q: Query "LT AZ Q Filter Proc"; Name: Text)
    var
        R: Text;
    begin
        R := '-';
        Observer.Observe(Name + '_ok', Format(TryReadKindF(Q, R)));
        Observer.Observe(Name, R);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure FilterElement_ReadInQueryProcedure()
    var
        Q: Query "LT AZ Q Filter Proc";
        Q2: Query "LT AZ Q Filter Proc";
    begin
        SeedHeads();
        ObserveKindF(Q, 'nofilter_closed');
        Q.SetRange(KindF, 'K1');
        ObserveKindF(Q, 'setrange_closed');
        Q.Open();
        ObserveKindF(Q, 'setrange_open');
        Q.Read();
        ObserveKindF(Q, 'setrange_read');
        Observer.Observe('getfilter', Q.GetFilter(KindF));
        Q2.SetFilter(KindF, 'K1|K2');
        Q2.Open();
        Q2.Read();
        ObserveKindF(Q2, 'setfilter_read');
        Observer.Finish();
    end;

    // ---- item 8: TopNumberOfRows and SecurityFiltering set after Open ----

    [TryFunction]
    local procedure TryReadAll(var Q: Query "LT AZ Q Rows"; var R: Text)
    begin
        while Q.Read() do
            R += Format(Q.Id) + ';';
    end;

    local procedure ObserveRead(var Q: Query "LT AZ Q Rows"; Name: Text)
    var
        R: Text;
    begin
        Observer.Observe(Name + '_ok', Format(TryReadAll(Q, R)));
        Observer.Observe(Name + '_rows', R);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure TopNumberOfRows_AfterOpen()
    var
        Q: Query "LT AZ Q Rows";
        Q2: Query "LT AZ Q Rows";
    begin
        SeedHeads();
        Q.Open();
        Q.TopNumberOfRows(2);
        ObserveRead(Q, 'before_first_read');
        Q.Open();
        ObserveRead(Q, 'reopen');
        Q2.Open();
        Q2.Read();
        Q2.TopNumberOfRows(1);
        ObserveRead(Q2, 'after_first_read');
        Observer.Observe('top_value', Format(Q2.TopNumberOfRows()));
        Observer.Finish();
    end;

    [Test]
    procedure SecurityFiltering_AfterOpen()
    var
        Q: Query "LT AZ Q Rows";
        Q2: Query "LT AZ Q Rows";
    begin
        SeedHeads();
        Q.Open();
        Q.SecurityFiltering(SecurityFilter::Filtered);
        ObserveRead(Q, 'before_first_read');
        Q2.Open();
        Q2.Read();
        Q2.SecurityFiltering(SecurityFilter::Ignored);
        ObserveRead(Q2, 'after_first_read');
        Observer.Observe('value', Format(Q2.SecurityFiltering()));
        Observer.Finish();
    end;
}
