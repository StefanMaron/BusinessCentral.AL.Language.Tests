// Probe writer-c, round 3: Record.FilterGroup(-1), the OR group (docs/probes-needed.md "FilterGroup(-1), the OR group (issue 17)").
// Observe-only. Rows: 1 A blank only, 2 B blank only, 3 both blank, 4 neither (C = 'c1'/'c2' as noted).
// Fixtures: table 69773, codeunit 69774.

table 69773 "PW FG Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Code[10]) { }
        field(3; B; Code[10]) { }
        field(4; C; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69774 "PW FilterGroup Or Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Seed()
    var
        R: Record "PW FG Row";
    begin
        R.DeleteAll();
        Add(1, '', 'x', 'c1');
        Add(2, 'x', '', 'c2');
        Add(3, '', '', 'c1');
        Add(4, 'x', 'x', 'c2');
    end;

    local procedure Add(Id: Integer; A: Code[10]; B: Code[10]; C: Code[10])
    var
        R: Record "PW FG Row";
    begin
        R.Id := Id;
        R.A := A;
        R.B := B;
        R.C := C;
        R.Insert();
    end;

    local procedure Ids(var R: Record "PW FG Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ' ';
            until R.Next() = 0;
        exit(Result + '(count=' + Format(R.Count()) + ')');
    end;

    [Test]
    procedure OrGroup_TwoFields_BothBlankFilters()
    var
        R: Record "PW FG Row";
    begin
        Seed();
        R.FilterGroup(-1);
        R.SetRange(A, '');
        R.SetRange(B, '');
        Observer.Observe('rows_in_group_minus1', Ids(R));
        Observer.Observe('getfilters_in_group_minus1', R.GetFilters());
        Observer.Observe('hasfilter_in_group_minus1', Format(R.HasFilter()));
        R.FilterGroup(0);
        Observer.Observe('rows_after_group0', Ids(R));
        Observer.Observe('getfilters_group0', R.GetFilters());
        Observer.Observe('hasfilter_group0', Format(R.HasFilter()));
        Observer.Expect('rows_in_group_minus1', '1 2 3 (count=3)');
        Observer.Expect('getfilters_in_group_minus1', 'A: '''', B: ''''');
        Observer.Expect('hasfilter_in_group_minus1', 'Yes');
        Observer.Expect('rows_after_group0', '1 2 3 (count=3)');
        Observer.Expect('getfilters_group0', '');
        Observer.Expect('hasfilter_group0', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_ReturnValueAndCurrentGroup()
    var
        R: Record "PW FG Row";
    begin
        Observer.Observe('previous_when_setting_minus1', Format(R.FilterGroup(-1)));
        Observer.Observe('current_after_minus1', Format(R.FilterGroup()));
        Observer.Observe('previous_when_setting_0', Format(R.FilterGroup(0)));
        Observer.Observe('current_after_0', Format(R.FilterGroup()));
        Observer.Expect('previous_when_setting_minus1', '-1');
        Observer.Expect('current_after_minus1', '-1');
        Observer.Expect('previous_when_setting_0', '0');
        Observer.Expect('current_after_0', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_WithFilterInGroupZero()
    var
        R: Record "PW FG Row";
    begin
        Seed();
        R.SetRange(C, 'c1');
        R.FilterGroup(-1);
        R.SetRange(A, '');
        R.SetRange(B, '');
        Observer.Observe('rows_group0_c1_and_or_group', Ids(R));
        Observer.Observe('getfilters_in_group_minus1', R.GetFilters());
        R.FilterGroup(0);
        Observer.Observe('getfilters_group0', R.GetFilters());
        Observer.Observe('rows_group0', Ids(R));
        Observer.Expect('rows_group0_c1_and_or_group', '1 3 (count=2)');
        Observer.Expect('getfilters_in_group_minus1', 'A: '''', B: ''''');
        Observer.Expect('getfilters_group0', 'C: C1');
        Observer.Expect('rows_group0', '1 3 (count=2)');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_OneFieldOnly()
    var
        R: Record "PW FG Row";
    begin
        Seed();
        R.FilterGroup(-1);
        R.SetRange(A, '');
        Observer.Observe('rows_one_field', Ids(R));
        Observer.Observe('getfilters', R.GetFilters());
        Observer.Expect('rows_one_field', '1 3 (count=2)');
        Observer.Expect('getfilters', 'A: ''''');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_SameFieldTwice()
    var
        R: Record "PW FG Row";
    begin
        Seed();
        R.FilterGroup(-1);
        R.SetRange(A, '');
        R.SetRange(A, 'x');
        Observer.Observe('rows_same_field_twice', Ids(R));
        Observer.Observe('getfilters', R.GetFilters());
        Observer.Expect('rows_same_field_twice', '2 4 (count=2)');
        Observer.Expect('getfilters', 'A: X');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_FieldFilteredInGroupZeroAndInOrGroup()
    var
        R: Record "PW FG Row";
    begin
        Seed();
        R.SetRange(A, 'x');
        R.FilterGroup(-1);
        R.SetRange(A, '');
        R.SetRange(B, '');
        Observer.Observe('rows', Ids(R));
        Observer.Observe('getfilters_in_group_minus1', R.GetFilters());
        R.FilterGroup(0);
        Observer.Observe('getfilters_group0', R.GetFilters());
        Observer.Expect('rows', '2 (count=1)');
        Observer.Expect('getfilters_in_group_minus1', 'A: '''', B: ''''');
        Observer.Expect('getfilters_group0', 'A: X');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_ResetAndCopyFilters()
    var
        R: Record "PW FG Row";
        R2: Record "PW FG Row";
    begin
        Seed();
        R.FilterGroup(-1);
        R.SetRange(A, '');
        R.SetRange(B, '');
        R.FilterGroup(0);
        R2.CopyFilters(R);
        Observer.Observe('rows_copyfilters_target', Ids(R2));
        R.Reset();
        Observer.Observe('rows_after_reset', Ids(R));
        R.FilterGroup(-1);
        Observer.Observe('getfilters_group_minus1_after_reset', R.GetFilters());
        Observer.Expect('rows_copyfilters_target', '1 2 3 (count=3)');
        Observer.Expect('rows_after_reset', '1 2 3 4 (count=4)');
        Observer.Expect('getfilters_group_minus1_after_reset', '');
        Observer.Verify();
    end;

    [Test]
    procedure OrGroup_RecordRef()
    var
        R: Record "PW FG Row";
        RecRef: RecordRef;
        Count: Integer;
    begin
        Seed();
        RecRef.Open(Database::"PW FG Row");
        RecRef.FilterGroup(-1);
        RecRef.Field(R.FieldNo(A)).SetRange('');
        RecRef.Field(R.FieldNo(B)).SetRange('');
        Count := RecRef.Count();
        Observer.Observe('recref_count', Format(Count));
        Observer.Observe('recref_getfilters', RecRef.GetFilters());
        Observer.Expect('recref_count', '3');
        Observer.Expect('recref_getfilters', 'A: '''', B: ''''');
        Observer.Verify();
    end;
}
