// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 73580, test codeunit 73581
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a table with a DateFormula field and rows with and without a formula. SetFilter on the field with the empty text, with not-equal and the empty text
//   (as a literal and as a %1 argument), with two single quotes, and SetRange with an empty DateFormula: whether it raises, GetFilter and Count.
// BC versions: 27, 28, 29 by CI

table 73580 "LT FD Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Due; DateFormula) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

codeunit 73581 "LT Filter Empty DateFormula"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Seed()
    var
        R: Record "LT FD Row";
    begin
        R.DeleteAll();
        R.Code := 'NONE1';
        R.Insert();
        R.Code := 'NONE2';
        R.Insert();
        R.Code := 'DAY';
        Evaluate(R.Due, '<1D>');
        R.Insert();
        R.Code := 'MONTH';
        Evaluate(R.Due, '<1M>');
        R.Insert();
        Obs.Observe('total', Format(R.Count()));
    end;

    [TryFunction]
    local procedure TryRaw(var R: Record "LT FD Row"; Expr: Text)
    begin
        R.SetFilter(Due, Expr);
    end;

    [TryFunction]
    local procedure TryArg(var R: Record "LT FD Row"; Expr: Text; Arg: Text)
    begin
        R.SetFilter(Due, Expr, Arg);
    end;

    [TryFunction]
    local procedure TryRangeEmpty(var R: Record "LT FD Row")
    var
        Empty: DateFormula;
    begin
        R.SetRange(Due, Empty);
    end;

    local procedure Report(Name: Text; var R: Record "LT FD Row"; Ok: Boolean)
    begin
        if not Ok then begin
            Obs.Observe(Name, GetLastErrorText());
            ClearLastError();
            exit;
        end;
        Obs.Observe(Name + '.filter', R.GetFilter(Due));
        Obs.Observe(Name + '.count', Format(R.Count()));
    end;

    [Test]
    procedure DateFormula_SetFilter_EmptyText()
    var
        R: Record "LT FD Row";
    begin
        Seed();
        R.Reset();
        Report('empty', R, TryRaw(R, ''));
        R.Reset();
        Report('quotes', R, TryRaw(R, ''''''));
        R.Reset();
        Report('neq_quotes', R, TryRaw(R, '<>'''''));
        R.Reset();
        Report('neq_bare', R, TryRaw(R, '<>'));
        R.Reset();
        Report('arg_neq_empty', R, TryArg(R, '<>%1', ''));
        R.Reset();
        Report('arg_eq_empty', R, TryArg(R, '%1', ''));
        R.Reset();
        Report('range_empty', R, TryRangeEmpty(R));
        Obs.Finish();
    end;

    [Test]
    procedure DateFormula_SetFilter_Formulas()
    var
        R: Record "LT FD Row";
    begin
        Seed();
        R.Reset();
        Report('eq_day', R, TryRaw(R, '<1D>'));
        R.Reset();
        Report('neq_day', R, TryRaw(R, '<>%1', '<1D>'));
        R.Reset();
        Report('arg_neq_day', R, TryArg(R, '<>%1', '<1D>'));
        R.Reset();
        Report('or_empty_day', R, TryRaw(R, '''''|<1D>'));
        Obs.Finish();
    end;
}
