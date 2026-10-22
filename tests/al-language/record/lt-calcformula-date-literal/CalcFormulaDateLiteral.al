// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: 0D (the AL date literal, the empty date) inside the filter(...) of a CalcFormula on an own table: exist and count with filter(<> 0D), filter(0D), filter(<>0D); rows with an empty date only, then a dated row (assumption calcformula-filter-date-literal).
// BC versions: 29 (27 and 28 by CI)

table 70383 "LT CFDate Row"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Owner No."; Code[10]) { }
        field(3; "Posting Date"; Date) { }
    }
    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 70384 "LT CFDate Owner"
{
    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; "Has Dated"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(<> 0D)));
        }
        field(3; "Dated Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(<> 0D)));
        }
        field(4; "Empty Count"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(0D)));
        }
        field(5; "Dated Count Nospace"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT CFDate Row" where("Owner No." = field("No."), "Posting Date" = filter(<>0D)));
        }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70385 "LT CFDate Literal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT CFDate Row";
        Owner: Record "LT CFDate Owner";
    begin
        Row.DeleteAll();
        Owner.DeleteAll();
        Owner."No." := 'O1';
        Owner.Insert();
    end;

    local procedure AddRow(No: Integer; D: Date)
    var
        Row: Record "LT CFDate Row";
    begin
        Row."Entry No." := No;
        Row."Owner No." := 'O1';
        Row."Posting Date" := D;
        Row.Insert();
    end;

    local procedure ObserveFlow(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Owner: Record "LT CFDate Owner";
    begin
        Owner.Get('O1');
        Owner.CalcFields("Has Dated", "Dated Count", "Empty Count", "Dated Count Nospace");
        Observer.Observe(Prefix + '_has_dated', Format(Owner."Has Dated"));
        Observer.Observe(Prefix + '_dated_count', Format(Owner."Dated Count"));
        Observer.Observe(Prefix + '_empty_count', Format(Owner."Empty Count"));
        Observer.Observe(Prefix + '_dated_count_nospace', Format(Owner."Dated Count Nospace"));
    end;

    [Test]
    procedure NotEmptyDate_OnlyEmptyRows_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ObserveFlow(Observer, 'no_rows');
        AddRow(1, 0D);
        AddRow(2, 0D);
        ObserveFlow(Observer, 'two_empty');
        Observer.Expect('no_rows_has_dated', 'No');
        Observer.Expect('no_rows_dated_count', '0');
        Observer.Expect('no_rows_empty_count', '0');
        Observer.Expect('no_rows_dated_count_nospace', '0');
        Observer.Expect('two_empty_has_dated', 'No');
        Observer.Expect('two_empty_dated_count', '0');
        Observer.Expect('two_empty_empty_count', '2');
        Observer.Expect('two_empty_dated_count_nospace', '0');
        Observer.Verify();
    end;

    [Test]
    procedure NotEmptyDate_TodayRow_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        AddRow(1, 0D);
        AddRow(2, Today());
        ObserveFlow(Observer, 'today_row');
        Observer.Expect('today_row_has_dated', 'Yes');
        Observer.Expect('today_row_dated_count', '1');
        Observer.Expect('today_row_empty_count', '1');
        Observer.Expect('today_row_dated_count_nospace', '1');
        Observer.Verify();
    end;

    [Test]
    procedure NotEmptyDate_OnlyTodayRow_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        AddRow(1, Today());
        ObserveFlow(Observer, 'only_today');
        Observer.Expect('only_today_has_dated', 'Yes');
        Observer.Expect('only_today_dated_count', '1');
        Observer.Expect('only_today_empty_count', '0');
        Observer.Expect('only_today_dated_count_nospace', '1');
        Observer.Verify();
    end;
}
