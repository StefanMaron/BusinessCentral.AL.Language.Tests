// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-countapprox-method
// Scope: in-scope
// Fixtures used: tables 72200-72201, codeunit 72209 (P92Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.CountApprox against Count (filters, temporary, empty), Truncate with filters and on a temporary record
// BC versions: 29 (27 and 28 by CI)

codeunit 72215 "LT P92 Counts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CountApprox_SmallTable()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Observe('approx', Format(RecRef.CountApprox()));
        RecRef.Field(3).SetFilter('>%1', 10);
        Observer.Observe('count_filtered', Format(RecRef.Count()));
        Observer.Observe('approx_filtered', Format(RecRef.CountApprox()));
        RecRef.Field(1).SetRange('NOPE');
        Observer.Observe('approx_nomatch', Format(RecRef.CountApprox()));
        RecRef.Reset();
        Observer.Observe('approx_after_reset', Format(RecRef.CountApprox()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountApprox_Empty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        Item.DeleteAll();
        RecRef.Open(72200);
        Observer.Observe('approx_empty', Format(RecRef.CountApprox()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountApprox_AfterInsertAndDelete()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Init();
        RecRef.Field(1).Value := 'C1';
        RecRef.Insert();
        Observer.Observe('approx_after_insert', Format(RecRef.CountApprox()));
        RecRef.Field(1).SetRange('C1');
        RecRef.FindFirst();
        RecRef.Delete();
        RecRef.Reset();
        Observer.Observe('approx_after_delete', Format(RecRef.CountApprox()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountApprox_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        i: Integer;
    begin
        Helper.SeedItems();
        RecRef.Open(72200, true);
        Observer.Observe('empty', Format(RecRef.CountApprox()));
        for i := 1 to 3 do begin
            RecRef.Init();
            RecRef.Field(1).Value := 'T' + Format(i);
            RecRef.Insert();
        end;
        Observer.Observe('three', Format(RecRef.CountApprox()));
        Observer.Observe('count_three', Format(RecRef.Count()));
        RecRef.Field(1).SetRange('T2');
        Observer.Observe('filtered', Format(RecRef.CountApprox()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure CountApprox_Unopened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        N: Integer;
    begin
        asserterror N := RecRef.CountApprox();
        Observer.ObserveError('unopened');
        Observer.Finish();
    end;

    [Test]
    procedure Truncate_Unfiltered()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Truncate();
        Observer.Observe('recref_count', Format(RecRef.Count()));
        Observer.Observe('record_count', Format(Item.Count()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Truncate_WithFilter()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
        Item: Record "LT P92 Item";
    begin
        Helper.SeedItems();
        RecRef.Open(72200);
        RecRef.Field(3).SetFilter('>=%1', 20);
        RecRef.Truncate();
        Observer.Observe('count_filtered_after', Format(RecRef.Count()));
        RecRef.Reset();
        Observer.Observe('count_after', Format(RecRef.Count()));
        Observer.Observe('record_count', Format(Item.Count()));
        Observer.Observe('record_a1_left', Format(Item.Get('A1')));
        Observer.Observe('record_a2_left', Format(Item.Get('A2')));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Truncate_WithoutTriggerArgument()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P92 Helper";
        RecRef: RecordRef;
    begin
        Helper.SeedPairs();
        RecRef.Open(72201);
        Observer.Observe('before', Format(RecRef.Count()));
        RecRef.Truncate(false);
        Observer.Observe('after_false', Format(RecRef.Count()));
        RecRef.Close();
        Observer.Finish();
    end;

    [Test]
    procedure Truncate_Unopened()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        asserterror RecRef.Truncate();
        Observer.ObserveError('unopened');
        Observer.Finish();
    end;
}
