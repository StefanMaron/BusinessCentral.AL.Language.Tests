// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-temporary-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own table 86506, callee codeunit 86507, test codeunit 86508
// Probe: writer QD, for the al-runtime-rs assumption stored-record-to-temporary-parameter. Observed values; every literal asserted below is
//   what the BC tier produced. The reverse direction (a temporary record to a parameter that is not temporary) is pinned in
//   record/lt-temp-record-by-value/TempRecordByValue.al; a stored record to a temporary subscriber parameter in events/lt-cl-event-leads.
// Facts: a stored (database) record with rows, a current row and a filter passed by value to a parameter declared `temporary` of a normal
//   procedure (not an event subscriber): IsTemporary, Count, the field values and filters the callee sees, Get / FindFirst, Insert and
//   Modify in the callee, then the stored table and the caller's record after the call.
// Results: the callee gets a temporary record over an EMPTY table (Count 0, Get and FindFirst fail) that holds the caller's current field
//   values but not its filters; Insert and Modify in the callee write only that temporary table; the caller's record, filters and the stored
//   table are unchanged. Modify of the handed current row fails (it is not in the temporary table). Same as for a temporary subscriber parameter.
// Writer QF: own table 86646 (secondary key on Name), callee codeunit 86645, tests QF_* in 86508. Results: a stored record with
//   SetCurrentKey(Name) + Ascending(false), or with marks and MarkedOnly(true), handed by value to a `temporary` parameter: the callee sees the
//   primary key ascending (GetView 'VERSION(1) SORTING(Field1)'), MarkedOnly No, Mark No, and its own rows sort by the primary key and are
//   all unmarked; the caller keeps its key, order, marks and MarkedOnly.
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

    // Writer QF (al-runtime-rs refusal: a current key, sort order or marks on a stored record handed to a `temporary` parameter): what the
    // callee sees of the caller's key, sort order and marks, how its own rows sort and which of them count as marked, and the caller after.
    [Test]
    procedure QF_StoredRecord_KeyAndOrder_ToTemporaryParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT QF TP Callee";
        Stored: Record "LT QF TP Row";
    begin
        QfSeed();
        Stored.SetCurrentKey(Name);
        Stored.Ascending(false);
        Stored.FindFirst();
        Callee.KeyAndOrder(Stored, Observer);
        Observer.Observe('caller.key', Stored.CurrentKey());
        Observer.Observe('caller.ascending', Format(Stored.Ascending()));
        Observer.Observe('caller.view', Stored.GetView(false));
        Observer.Observe('caller.current', Format(Stored.Id) + '=' + Stored.Name);
        Observer.Observe('caller.order', QfOrder(Stored));
        Observer.Expect('callee.isTemporary', 'Yes');
        Observer.Expect('callee.key', 'Id');
        Observer.Expect('callee.ascending', 'Yes');
        Observer.Expect('callee.view', 'VERSION(1) SORTING(Field1)');
        Observer.Expect('callee.current', '1=c');
        Observer.Expect('callee.order', '1,2,3,');
        Observer.Expect('callee.keyAfter', 'Id');
        Observer.Expect('callee.ascendingAfter', 'Yes');
        Observer.Expect('caller.key', 'Name');
        Observer.Expect('caller.ascending', 'No');
        Observer.Expect('caller.view', 'VERSION(1) SORTING(Field2) ORDER(1)');
        Observer.Expect('caller.current', '1=c');
        Observer.Expect('caller.order', '1,3,2,');
        Observer.Verify();
    end;

    [Test]
    procedure QF_StoredRecord_Marks_ToTemporaryParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT QF TP Callee";
        Stored: Record "LT QF TP Row";
    begin
        QfSeed();
        Stored.Get(1);
        Stored.Mark(true);
        Stored.Get(3);
        Stored.Mark(true);
        Stored.MarkedOnly(true);
        Callee.Marks(Stored, Observer);
        Observer.Observe('caller.markedOnly', Format(Stored.MarkedOnly()));
        Observer.Observe('caller.count', Format(Stored.Count()));
        Observer.Observe('caller.mark', Format(Stored.Mark()));
        Observer.Observe('caller.order', QfOrder(Stored));
        Observer.Expect('callee.markedOnly', 'No');
        Observer.Expect('callee.mark', 'No');
        Observer.Expect('callee.current', '3=b');
        Observer.Expect('callee.count', '0');
        Observer.Expect('callee.countFilled', '3');
        Observer.Expect('callee.orderFilled', '1,2,3,');
        Observer.Expect('callee.countAll', '3');
        Observer.Expect('callee.marks', '1=No,2=No,3=No,');
        Observer.Expect('caller.markedOnly', 'Yes');
        Observer.Expect('caller.count', '2');
        Observer.Expect('caller.mark', 'Yes');
        Observer.Expect('caller.order', '1,3,');
        Observer.Verify();
    end;

    [Test]
    procedure QF_StoredRecord_MarksNotMarkedOnly_ToTemporaryParameter()
    var
        Observer: Codeunit "Probe Observer";
        Callee: Codeunit "LT QF TP Callee";
        Stored: Record "LT QF TP Row";
    begin
        QfSeed();
        Stored.Get(2);
        Stored.Mark(true);
        Callee.Marks(Stored, Observer);
        Observer.Observe('caller.markedOnly', Format(Stored.MarkedOnly()));
        Observer.Observe('caller.mark', Format(Stored.Mark()));
        Observer.Expect('callee.markedOnly', 'No');
        Observer.Expect('callee.mark', 'No');
        Observer.Expect('callee.current', '2=a');
        Observer.Expect('callee.count', '0');
        Observer.Expect('callee.countFilled', '3');
        Observer.Expect('callee.orderFilled', '1,2,3,');
        Observer.Expect('callee.countAll', '3');
        Observer.Expect('callee.marks', '1=No,2=No,3=No,');
        Observer.Expect('caller.markedOnly', 'No');
        Observer.Expect('caller.mark', 'Yes');
        Observer.Verify();
    end;

    local procedure QfSeed()
    var
        Row: Record "LT QF TP Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'c';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'a';
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'b';
        Row.Insert();
    end;

    local procedure QfOrder(var Row: Record "LT QF TP Row"): Text
    var
        Ids: Text;
    begin
        if Row.FindSet() then
            repeat
                Ids += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Ids);
    end;
}

table 86646 "LT QF TP Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByName; Name) { }
    }
}

codeunit 86645 "LT QF TP Callee"
{
    procedure KeyAndOrder(R: Record "LT QF TP Row" temporary; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('callee.isTemporary', Format(R.IsTemporary()));
        Observer.Observe('callee.key', R.CurrentKey());
        Observer.Observe('callee.ascending', Format(R.Ascending()));
        Observer.Observe('callee.view', R.GetView(false));
        Observer.Observe('callee.current', Format(R.Id) + '=' + R.Name);
        Fill(R);
        Observer.Observe('callee.order', Order(R));
        Observer.Observe('callee.keyAfter', R.CurrentKey());
        Observer.Observe('callee.ascendingAfter', Format(R.Ascending()));
    end;

    procedure Marks(R: Record "LT QF TP Row" temporary; var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('callee.markedOnly', Format(R.MarkedOnly()));
        Observer.Observe('callee.mark', Format(R.Mark()));
        Observer.Observe('callee.current', Format(R.Id) + '=' + R.Name);
        Observer.Observe('callee.count', Format(R.Count()));
        Fill(R);
        Observer.Observe('callee.countFilled', Format(R.Count()));
        Observer.Observe('callee.orderFilled', Order(R));
        R.MarkedOnly(false);
        Observer.Observe('callee.countAll', Format(R.Count()));
        Observer.Observe('callee.marks', MarkList(R));
    end;

    local procedure Fill(var R: Record "LT QF TP Row" temporary)
    begin
        R.Id := 1;
        R.Name := 'c';
        R.Insert();
        R.Id := 2;
        R.Name := 'a';
        R.Insert();
        R.Id := 3;
        R.Name := 'b';
        R.Insert();
    end;

    local procedure Order(var R: Record "LT QF TP Row" temporary): Text
    var
        Ids: Text;
    begin
        if R.FindSet() then
            repeat
                Ids += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(Ids);
    end;

    local procedure MarkList(var R: Record "LT QF TP Row" temporary): Text
    var
        Ids: Text;
    begin
        if R.FindSet() then
            repeat
                Ids += Format(R.Id) + '=' + Format(R.Mark()) + ',';
            until R.Next() = 0;
        exit(Ids);
    end;
}
