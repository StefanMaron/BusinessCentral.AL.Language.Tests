// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setascending-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); table 78007 "LT AD Tie Row"
// Probe: the order of rows whose sort field value ties (same Grp, different primary key Id) after SetCurrentKey(Grp), Ascending(false),
// SetAscending(Grp, ...) and combinations of them, read with FindSet, FindFirst, FindLast and Next(-1); and SetAscending on a field that is not
// in the current key after Ascending(false). Object ids 78007 - 78008.

table 78007 "LT AD Tie Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grp; Integer) { }
        field(3; Qty; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByGrp; Grp) { }
        key(ByGrpId; Grp, Id) { }
    }
}

codeunit 78008 "LT AD SetAscending Ties"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT AD Tie Row";
        Index: Integer;
    begin
        Row.DeleteAll();
        for Index := 1 to 6 do begin
            Row.Init();
            Row.Id := Index;
            Row.Grp := (Index - 1) div 3 + 1;
            Row.Qty := Index mod 2;
            Row.Insert();
        end;
    end;

    local procedure Ids(var Row: Record "LT AD Tie Row"): Text
    var
        Result: Text;
    begin
        if Row.FindSet() then
            repeat
                Result += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Result);
    end;

    local procedure Backwards(var Row: Record "LT AD Tie Row"): Text
    var
        Result: Text;
    begin
        if Row.FindLast() then
            repeat
                Result += Format(Row.Id) + ',';
            until Row.Next(-1) = 0;
        exit(Result);
    end;

    local procedure Ends(var Row: Record "LT AD Tie Row"): Text
    var
        First: Integer;
        Last: Integer;
    begin
        if Row.FindFirst() then
            First := Row.Id;
        if Row.FindLast() then
            Last := Row.Id;
        exit('first=' + Format(First) + '|last=' + Format(Last));
    end;

    local procedure All(var Row: Record "LT AD Tie Row"): Text
    begin
        exit(Ids(Row) + '|back=' + Backwards(Row) + '|' + Ends(Row) + '|view=' + Row.GetView(false));
    end;

    [TryFunction]
    local procedure TrySetAscendingId(var Row: Record "LT AD Tie Row"; Asc: Boolean)
    begin
        Row.SetAscending(Id, Asc);
    end;

    local procedure IdCase(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT AD Tie Row"; Asc: Boolean)
    begin
        ClearLastError();
        if TrySetAscendingId(Row, Asc) then
            Observer.Observe(Name, 'ok|' + All(Row))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySetAscending(var Row: Record "LT AD Tie Row"; Asc: Boolean)
    begin
        Row.SetAscending(Qty, Asc);
    end;

    [Test]
    procedure Ties_Basic()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Tie Row";
    begin
        Seed();
        Row.SetCurrentKey(Grp);
        Observer.Observe('key_grp', All(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Observer.Observe('key_grp_ascending_false', All(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp);
        Row.SetAscending(Grp, false);
        Observer.Observe('key_grp_setascending_grp_false', All(Row));
        Observer.Finish();
    end;

    [Test]
    procedure Ties_AscendingFalseThenSetAscending()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Tie Row";
    begin
        Seed();
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        Row.SetAscending(Grp, true);
        Observer.Observe('desc_then_grp_asc', All(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        IdCase(Observer, 'desc_then_id_asc', Row, true);
        Row.Reset();
        Row.SetCurrentKey(Grp);
        IdCase(Observer, 'id_desc_only', Row, false);
        Row.Reset();
        Row.SetCurrentKey(Grp);
        Row.SetAscending(Grp, false);
        IdCase(Observer, 'grp_desc_id_asc', Row, true);
        Observer.Finish();
    end;

    [Test]
    procedure Ties_ExplicitPrimaryKeyInKey()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Tie Row";
    begin
        Seed();
        Row.SetCurrentKey(Grp, Id);
        Row.SetAscending(Grp, false);
        Observer.Observe('grp_desc_id_asc', All(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp, Id);
        Row.SetAscending(Grp, true);
        Row.SetAscending(Id, false);
        Observer.Observe('grp_asc_id_desc', All(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp, Id);
        Row.Ascending(false);
        Row.SetAscending(Id, true);
        Observer.Observe('all_desc_id_asc', All(Row));
        Observer.Finish();
    end;

    [Test]
    procedure Ties_NonKeyField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Tie Row";
    begin
        Seed();
        Row.SetCurrentKey(Grp);
        Row.Ascending(false);
        ClearLastError();
        if TrySetAscending(Row, true) then
            Observer.Observe('qty_asc', 'ok|' + All(Row))
        else
            Observer.Observe('qty_asc', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Finish();
    end;

    [Test]
    procedure Ties_PrimaryKeyCurrent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AD Tie Row";
    begin
        Seed();
        Row.Ascending(false);
        Row.SetRange(Grp, 1);
        Observer.Observe('pk_desc_grp1', All(Row));
        Row.Reset();
        Row.SetCurrentKey(Grp);
        Row.SetRange(Grp, 2);
        Row.Ascending(false);
        Observer.Observe('grp_desc_range2', All(Row));
        Observer.Finish();
    end;
}
