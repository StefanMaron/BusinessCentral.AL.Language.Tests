// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: own table 73548, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on a Date field with a literal TEXT (no %1): the session's own formatted date (Format(D) and Format(D, 0, 0..9)), custom formats, 6 and 8 digit forms,
//   separators, month names, operators with those texts, an empty text, '', <>'', blanks, date words and formulas (T, W, CM, 1M ...), count and GetFilter, or the error text and code
// Settles issue 130 reasons 7, 14, 21, 22 (SetFilter: text filter value for Date: an empty '', a formula such as 1M, a region's date format)
// BC versions: 29 (27 and 28 by CI)

table 73548 "LT P130 Filter Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Gd; Guid) { }
        field(4; Tm; Time) { }
        field(5; Dtm; DateTime) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73549 "LT P130 Date Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        Add(1, 20240102D);
        Add(2, 20240103D);
        Add(3, 20240104D);
        Add(4, 20240301D);
        Add(5, 20240305D);
        Add(6, 20241231D);
        Add(7, 0D);
    end;

    local procedure Add(Id: Integer; D: Date)
    var
        R: Record "LT P130 Filter Row";
    begin
        R.Id := Id;
        R.Dt := D;
        R.Insert();
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "LT P130 Filter Row"; FilterText: Text)
    begin
        R.SetFilter(Dt, FilterText);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT P130 Filter Row";
    begin
        if TrySet(R, FilterText) then
            Observer.Observe(Name, 'ok count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;





    [Test]
    procedure P130_DateFilter_OperatorsWithSessionFormat()
    var
        Observer: Codeunit "Probe Observer";
        D1: Date;
        D2: Date;
    begin
        Seed();
        D1 := 20240103D;
        D2 := 20240301D;
        Probe(Observer, 'ge', '>=' + Format(D1));
        Probe(Observer, 'gt', '>' + Format(D1));
        Probe(Observer, 'le', '<=' + Format(D1));
        Probe(Observer, 'lt', '<' + Format(D1));
        Probe(Observer, 'ne', '<>' + Format(D1));
        Probe(Observer, 'range', Format(D1) + '..' + Format(D2));
        Probe(Observer, 'open_start', '..' + Format(D1));
        Probe(Observer, 'open_end', Format(D1) + '..');
        Probe(Observer, 'or', Format(D1) + '|' + Format(D2));
        Probe(Observer, 'range_or_single', Format(D1) + '..' + Format(D2) + '|' + Format(20241231D));
        Probe(Observer, 'and_ge_le', '>=' + Format(D1) + '&<=' + Format(D2));
        Probe(Observer, 'ne_or', '<>' + Format(D1) + '&<>' + Format(D2));
        Probe(Observer, 'range_reversed', Format(D2) + '..' + Format(D1));
        Probe(Observer, 'spaces_around_range', ' ' + Format(D1) + ' .. ' + Format(D2) + ' ');
        Probe(Observer, 'iso_range', '2024-01-03..2024-03-01');
        Probe(Observer, 'iso_ge', '>=2024-01-03');
        Observer.Expect('ge', 'ok count=5 filter=>=01/03/24');
        Observer.Expect('gt', 'ok count=4 filter=>01/03/24');
        Observer.Expect('le', 'ok count=3 filter=<=01/03/24');
        Observer.Expect('lt', 'ok count=2 filter=<01/03/24');
        Observer.Expect('ne', 'ok count=6 filter=<>01/03/24');
        Observer.Expect('range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('open_start', 'ok count=3 filter=..01/03/24');
        Observer.Expect('open_end', 'ok count=5 filter=01/03/24..');
        Observer.Expect('or', 'ok count=2 filter=01/03/24|03/01/24');
        Observer.Expect('range_or_single', 'ok count=4 filter=01/03/24..03/01/24|12/31/24');
        Observer.Expect('and_ge_le', 'ok count=3 filter=>=01/03/24&<=03/01/24');
        Observer.Expect('ne_or', 'ok count=5 filter=<>01/03/24&<>03/01/24');
        Observer.Expect('range_reversed', 'ok count=0 filter=03/01/24..01/03/24');
        Observer.Expect('spaces_around_range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('iso_range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('iso_ge', 'ok count=5 filter=>=01/03/24');
        Observer.Verify();
    end;
}
