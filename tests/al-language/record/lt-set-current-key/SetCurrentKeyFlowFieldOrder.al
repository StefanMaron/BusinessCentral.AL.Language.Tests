// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setcurrentkey-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (tables 74317 and 74318)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the order FindSet gives after SetCurrentKey on a FlowField whose flowed values run against the primary key order, with Ascending(false), with SetCurrentKey(FlowField, Id), after a CalcFields of the loop record, and the key CurrentKey reports
// Settles docs/probes-needed.md row "SetCurrentKey on a FlowField" (Probe fixes): "accepted, orders by the primary key; the order of a FlowField key is not pinned" (the acceptance is pinned in records/W4SortKeys.al:459)
// BC versions: 29 (27 and 28 by CI)

table 74317 "LT P166 Key Owner"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P166 Key Line" where(OwnerId = field(Id)));
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 74318 "LT P166 Key Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; OwnerId; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74319 "LT P166 Key Flow Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Owner: Record "LT P166 Key Owner";
        Line: Record "LT P166 Key Line";
        n: Integer;
    begin
        Owner.DeleteAll();
        Line.DeleteAll();
        // owner 1 has 3 lines, owner 2 has 1, owner 3 has 2: ascending Cnt order is 2, 3, 1
        Owner.Id := 1; Owner.Name := 'three'; Owner.Insert();
        Owner.Id := 2; Owner.Name := 'one'; Owner.Insert();
        Owner.Id := 3; Owner.Name := 'two'; Owner.Insert();
        for n := 1 to 3 do begin
            Line.Id := n; Line.OwnerId := 1; Line.Insert();
        end;
        Line.Id := 4; Line.OwnerId := 2; Line.Insert();
        Line.Id := 5; Line.OwnerId := 3; Line.Insert();
        Line.Id := 6; Line.OwnerId := 3; Line.Insert();
    end;

    [TryFunction]
    local procedure TryKey1(var Owner: Record "LT P166 Key Owner")
    begin
        Owner.SetCurrentKey(Cnt);
    end;

    [TryFunction]
    local procedure TryKey2(var Owner: Record "LT P166 Key Owner")
    begin
        Owner.SetCurrentKey(Cnt, Id);
    end;

    [TryFunction]
    local procedure TryLoop(var Owner: Record "LT P166 Key Owner"; CalcEach: Boolean; var Order: Text)
    begin
        Order := '';
        if Owner.FindSet() then
            repeat
                if CalcEach then
                    Owner.CalcFields(Cnt);
                Order += Format(Owner.Id) + ':' + Format(Owner.Cnt) + ' ';
            until Owner.Next() = 0;
    end;

    [Test]
    procedure SetCurrentKey_FlowField_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Observer.Observe('keyOk', Format(TryKey1(Owner)));
        Observer.ObserveError('key');
        Observer.Observe('currentKey', Owner.CurrentKey());
        Observer.Observe('loopOk', Format(TryLoop(Owner, false, Order)));
        Observer.Observe('orderNoCalc', Order);
        Observer.Observe('loopCalcOk', Format(TryLoop(Owner, true, Order)));
        Observer.Observe('orderCalc', Order);
        Observer.Expect('keyOk', 'Yes');
        Observer.Expect('key|text', '');
        Observer.Expect('key|code', '');
        Observer.Expect('currentKey', 'Cnt');
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('orderNoCalc', '2:1 3:2 1:3 ');
        Observer.Expect('loopCalcOk', 'Yes');
        Observer.Expect('orderCalc', '2:1 3:2 1:3 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_FlowField_Descending()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Observer.Observe('keyOk', Format(TryKey1(Owner)));
        Owner.Ascending(false);
        Observer.Observe('loopOk', Format(TryLoop(Owner, true, Order)));
        Observer.ObserveError('loop');
        Observer.Observe('order', Order);
        Observer.Expect('keyOk', 'Yes');
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('loop|text', '');
        Observer.Expect('loop|code', '');
        Observer.Expect('order', '1:3 3:2 2:1 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_FlowFieldThenPrimaryKey_FindSetOrder()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Observer.Observe('keyOk', Format(TryKey2(Owner)));
        Observer.ObserveError('key');
        Observer.Observe('currentKey', Owner.CurrentKey());
        Observer.Observe('loopOk', Format(TryLoop(Owner, true, Order)));
        Observer.ObserveError('loop');
        Observer.Observe('order', Order);
        Observer.Expect('keyOk', 'Yes');
        Observer.Expect('key|text', '');
        Observer.Expect('key|code', '');
        Observer.Expect('currentKey', 'Cnt,Id');
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('loop|text', '');
        Observer.Expect('loop|code', '');
        Observer.Expect('order', '2:1 3:2 1:3 ');
        Observer.Verify();
    end;

    [Test]
    procedure SetCurrentKey_PrimaryKeyOrderForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Owner: Record "LT P166 Key Owner";
        Order: Text;
    begin
        Seed();
        Owner.SetCurrentKey(Id);
        Observer.Observe('loopOk', Format(TryLoop(Owner, true, Order)));
        Observer.Observe('order', Order);
        Owner.Ascending(false);
        Observer.Observe('loopDescOk', Format(TryLoop(Owner, true, Order)));
        Observer.Observe('orderDesc', Order);
        Observer.Expect('loopOk', 'Yes');
        Observer.Expect('order', '1:3 2:1 3:2 ');
        Observer.Expect('loopDescOk', 'Yes');
        Observer.Expect('orderDesc', '3:2 2:1 1:3 ');
        Observer.Verify();
    end;
}
