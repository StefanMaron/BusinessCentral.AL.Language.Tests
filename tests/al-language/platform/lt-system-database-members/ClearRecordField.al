// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-clear-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74013
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Clear on a field of a record: zero or InitValue; Clear of whole record with InitValue; filters and the Rec of a temp record
// BC versions: 29 (27 and 28 by CI)
// Tag: P95

table 74012 "LT P95 CRow74012"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Name; Text[50]) { InitValue = 'Init'; }
        field(3; Qty; Integer) { InitValue = 5; }
        field(4; Flag; Boolean) { InitValue = true; }
        field(5; Amt; Decimal) { }
    }
    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 74013 "LT P95 Clear Record Field"
{
    Subtype = Test;
    TestPermissions = Disabled;


    [Test]
    procedure ClearRecordField()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P95 CRow74012";
        Tmp: Record "LT P95 CRow74012" temporary;
    begin
        Row.Init();
        Observer.Observe('init_values', Row.Name + '|' + Format(Row.Qty) + '|' + Format(Row.Flag));
        Row."No." := 'A';
        Row.Name := 'changed';
        Row.Qty := 9;
        Row.Flag := false;
        Row.Amt := 1.5;
        Clear(Row.Name);
        Clear(Row.Qty);
        Clear(Row.Flag);
        Clear(Row.Amt);
        Clear(Row."No.");
        Observer.Observe('after_field_clear', '[' + Row.Name + ']|' + Format(Row.Qty) + '|' + Format(Row.Flag) + '|' + Format(Row.Amt) + '|[' + Row."No." + ']');
        Row.Name := 'changed';
        Row.Qty := 9;
        Row.SetRange(Qty, 3);
        Clear(Row);
        Observer.Observe('after_record_clear', '[' + Row.Name + ']|' + Format(Row.Qty) + '|' + Format(Row.Flag) + '|' + Row.GetFilters());
        Tmp."No." := 'T1';
        Tmp.Insert();
        Tmp.SetRange("No.", 'X');
        Clear(Tmp);
        Observer.Observe('temp_after_clear_count', Format(Tmp.Count()) + '|' + Tmp.GetFilters());

        Observer.Finish();
    end;

}
