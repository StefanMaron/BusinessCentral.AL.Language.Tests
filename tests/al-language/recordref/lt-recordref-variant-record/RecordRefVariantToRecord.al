// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: A Record variable assigned a Variant holding a RecordRef (same table, other table, closed RecordRef) (assumption recordref-variant-to-record); types/lt-variant/VaTConvert.al covers scalar Variant conversions only.
// BC versions: 29 (27 and 28 by CI)

table 70653 "LT RRVar Row"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 70654 "LT RRVar Other"
{
    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 70655 "LT RRVar To Record"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT RRVar Row";
        Other: Record "LT RRVar Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row."No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row."No." := 2;
        Row.Name := 'second';
        Row.Insert();
        Other."No." := 7;
        Other.Name := 'other';
        Other.Insert();
    end;

    [TryFunction]
    local procedure TryAssign(V: Variant; var Row: Record "LT RRVar Row")
    begin
        Row := V;
    end;

    local procedure Outcome(V: Variant; var Row: Record "LT RRVar Row"): Text
    begin
        ClearLastError();
        if TryAssign(V, Row) then
            exit('ok');
        exit('error:' + GetLastErrorText());
    end;

    [Test]
    procedure RecordFromVariant_SameTable_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Row");
        RR.FindFirst();
        V := RR;
        Observer.Observe('is_recordref', Format(V.IsRecordRef()));
        Observer.Observe('is_record', Format(V.IsRecord()));
        Observer.Observe('assign_first', Outcome(V, Row));
        Observer.Observe('first_no', Format(Row."No."));
        Observer.Observe('first_name', Row.Name);
        RR.Next();
        V := RR;
        Observer.Observe('assign_second', Outcome(V, Row));
        Observer.Observe('second_no', Format(Row."No."));
        Observer.Observe('second_name', Row.Name);
        Observer.Expect('is_recordref', 'Yes');
        Observer.Expect('is_record', 'No');
        Observer.Expect('assign_first', 'ok');
        Observer.Expect('first_no', '1');
        Observer.Expect('first_name', 'first');
        Observer.Expect('assign_second', 'ok');
        Observer.Expect('second_no', '2');
        Observer.Expect('second_name', 'second');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_IsCopy_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
        Check: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Row");
        RR.FindFirst();
        V := RR;
        Observer.Observe('assign', Outcome(V, Row));
        Row.Name := 'changed in copy';
        Row.Modify();
        Check.Get(1);
        Observer.Observe('stored_after_modify', Check.Name);
        RR.Get(RR.RecordId());
        Observer.Observe('rr_name_after_modify', Format(RR.Field(2).Value()));
        Row.SetRange("No.", 2);
        Observer.Observe('copy_has_filter_no', Format(Row.HasFilter()));
        Observer.Expect('assign', 'ok');
        Observer.Expect('stored_after_modify', 'changed in copy');
        Observer.Expect('rr_name_after_modify', 'changed in copy');
        Observer.Expect('copy_has_filter_no', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_OtherTable_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Other");
        RR.FindFirst();
        V := RR;
        Observer.Observe('other_table', Outcome(V, Row));
        Observer.Observe('row_untouched_no', Format(Row."No."));
        Observer.Expect('other_table', 'error:The requested operation is not supported.');
        Observer.Expect('row_untouched_no', '0');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_ClosedRecordRef_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        V := RR;
        Observer.Observe('is_recordref', Format(V.IsRecordRef()));
        Observer.Observe('closed_recordref', Outcome(V, Row));
        Observer.Expect('is_recordref', 'Yes');
        Observer.Expect('closed_recordref', 'error:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavRecordRef to Microsoft.Dynamics.Nav.Runtime.INavRecordHandle.');
        Observer.Verify();
    end;

    [Test]
    procedure RecordFromVariant_OpenedNoCurrentRow_Result()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        V: Variant;
        Row: Record "LT RRVar Row";
    begin
        Seed();
        RR.Open(Database::"LT RRVar Row");
        V := RR;
        Row."No." := 55;
        Observer.Observe('opened_not_positioned', Outcome(V, Row));
        Observer.Observe('row_no_after', Format(Row."No."));
        Observer.Expect('opened_not_positioned', 'ok');
        Observer.Expect('row_no_after', '0');
        Observer.Verify();
    end;
}
