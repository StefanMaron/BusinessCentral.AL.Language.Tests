// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 86506, callee codeunit 86507, test codeunit 86508
// Probe: writer QD, for the al-runtime-rs assumption stored-record-to-temporary-parameter. Observed values; every literal asserted below is
//   what the BC tier produced. The reverse direction (a temporary record to a parameter that is not temporary) is pinned in
//   record/lt-temp-record-by-value/TempRecordByValue.al; a stored record to a temporary subscriber parameter in events/lt-cl-event-leads.
// Facts: a stored (database) record with rows, a current row and a filter passed by value to a parameter declared `temporary` of a normal
//   procedure (not an event subscriber): IsTemporary, Count, the field values and filters the callee sees, Get / FindFirst, Insert and
//   Modify in the callee, then the stored table and the caller's record after the call.
// BC versions: 27, 28, 29

table 86506 "LT QD TP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 86507 "LT QD TP Callee"
{
    procedure ToTemporary(R: Record "LT QD TP Row" temporary; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('callee.isTemporary', Format(R.IsTemporary()));
        Observer.Observe('callee.count', Format(R.Count()));
        Observer.Observe('callee.current', Format(R.Id) + '=' + R.Name);
        Observer.Observe('callee.filters', R.GetFilters());
        Observer.Observe('callee.get', Format(R.Get(R.Id)));
        Observer.Observe('callee.findFirst', Format(R.FindFirst()) + ':' + Format(R.Id) + '=' + R.Name);
        R.Id := 50;
        R.Name := 'inCallee';
        Observer.Observe('callee.insert', Format(R.Insert()));
        R.Name := 'modInCallee';
        Observer.Observe('callee.modify', Format(R.Modify()));
        R.SetRange(Id);
        Observer.Observe('callee.countAfter', Format(R.Count()));
        Observer.Observe('callee.isTemporaryAfter', Format(R.IsTemporary()));
    end;

    procedure ModifyCurrent(R: Record "LT QD TP Row" temporary; var Observer: Codeunit "Probe Observer")
    begin
        R.Name := 'modCurrent';
        Observer.Observe('modcur.modify', Format(R.Modify()));
        Observer.Observe('modcur.count', Format(R.Count()));
    end;
}

codeunit 86508 "LT QD Stored To Temp Param"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT QD TP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'three';
        Row.Insert();
    end;

    local procedure StoredRows(): Text
    var
        Row: Record "LT QD TP Row";
        Names: Text;
    begin
        if Row.FindSet() then
            repeat
                Names += Format(Row.Id) + '=' + Row.Name + ';';
            until Row.Next() = 0;
        exit(Names);
    end;

    [Test]
    procedure StoredRecord_ToTemporaryParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT QD TP Callee";
        Stored: Record "LT QD TP Row";
    begin
        Seed();
        Stored.SetRange(Id, 2, 3);
        Stored.FindFirst();
        Callee.ToTemporary(Stored, Observer);
        Observer.Observe('caller.isTemporary', Format(Stored.IsTemporary()));
        Observer.Observe('caller.current', Format(Stored.Id) + '=' + Stored.Name);
        Observer.Observe('caller.filters', Stored.GetFilters());
        Observer.Observe('caller.count', Format(Stored.Count()));
        Observer.Observe('stored.rows', StoredRows());
        Observer.Expect('callee.isTemporary', 'Yes');
        Observer.Expect('callee.count', '0');
        Observer.Expect('callee.current', '2=two');
        Observer.Expect('callee.filters', '');
        Observer.Expect('callee.get', 'No');
        Observer.Expect('callee.findFirst', 'No:2=two');
        Observer.Expect('callee.insert', 'Yes');
        Observer.Expect('callee.modify', 'Yes');
        Observer.Expect('callee.countAfter', '1');
        Observer.Expect('callee.isTemporaryAfter', 'Yes');
        Observer.Expect('caller.isTemporary', 'No');
        Observer.Expect('caller.current', '2=two');
        Observer.Expect('caller.filters', 'Id: 2..3');
        Observer.Expect('caller.count', '2');
        Observer.Expect('stored.rows', '1=one;2=two;3=three;');
        Observer.Verify();
    end;

    [Test]
    procedure StoredRecord_ToTemporaryParameter_ModifyCurrent()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT QD TP Callee";
        Stored: Record "LT QD TP Row";
    begin
        Seed();
        Stored.Get(1);
        Callee.ModifyCurrent(Stored, Observer);
        Observer.Observe('caller.current', Format(Stored.Id) + '=' + Stored.Name);
        Observer.Observe('stored.rows', StoredRows());
        Observer.Expect('modcur.modify', 'No');
        Observer.Expect('modcur.count', '0');
        Observer.Expect('caller.current', '1=one');
        Observer.Expect('stored.rows', '1=one;2=two;3=three;');
        Observer.Verify();
    end;
}
