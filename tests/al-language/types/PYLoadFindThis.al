// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-loadfields-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// Record.LoadFields(Field, ...) on a record that was never fetched: the statement form is accepted with a blank key (Name keeps what was assigned in memory, Id stays 0), the call does not
// read the row: with Id = 5 set and a stored row, Name is STILL empty afterwards, a field assigned before the call keeps its value, and Get + assign + LoadFields(Amount) keeps the assigned Name
// and loads the stored Amount (7). The function form `Ok := Row.LoadFields(...)` compiles and answers false in all the cases tried (existing key and missing key).
// Record.Find with the direction characters in the orders '=', '=><', '=<>', '<=>', '><=', '<>=', '>=<', '<=', '>=', '<>', '><': the results (found flag and the Id the record holds afterwards)
// for the keys 3 (present), 4, 0 and 9 (absent) are listed in the test; no rule is claimed in this header.
// Fixtures used: self-contained tables 69343 and 69344, codeunit 69343
// BC versions: 27.5, 29.0

table 69343 "PY Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 69344 "PY Item"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Label; Text[30]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69343 "PY LoadFields Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryLoad(var Row: Record "PY Row")
    begin
        Row.LoadFields(Name);
    end;

    [Test]
    procedure LoadFields_NeverFetchedRecord_BlankKey()
    var
        Row: Record "PY Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 0;
        Row.Name := 'inmemory';
        Row.LoadFields(Name, Amount);
        Observer.Observe('statement_form', 'ok');
        Observer.Observe('name_after', Row.Name);
        Observer.Observe('id_after', Format(Row.Id));
        Observer.Expect('statement_form', 'ok');
        Observer.Expect('name_after', 'inmemory');
        Observer.Expect('id_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_RowOfTheKeyExists_AndAssignedFieldInBetween()
    var
        Row: Record "PY Row";
        Other: Record "PY Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Other.Id := 5;
        Other.Name := 'stored';
        Other.Amount := 7;
        Other.Insert();
        Row.Id := 5;
        Row.LoadFields(Name);
        Observer.Observe('name_after_load_with_key_5', Row.Name);
        Clear(Row);
        Row.Id := 5;
        Row.Name := 'assigned';
        Row.LoadFields(Amount);
        Observer.Observe('name_kept_after_assign_then_load', Row.Name);
        Observer.Observe('amount_after_assign_then_load', Format(Row.Amount));
        Clear(Row);
        Row.Id := 99;
        Row.LoadFields(Name);
        Observer.Observe('name_after_load_with_missing_key', '[' + Row.Name + ']');
        Clear(Row);
        Row.Get(5);
        Row.Name := 'changed';
        Row.LoadFields(Amount);
        Observer.Observe('name_after_get_assign_load', Row.Name);
        Observer.Observe('amount_after_get_assign_load', Format(Row.Amount));
        Observer.Expect('name_after_load_with_key_5', '');
        Observer.Expect('name_kept_after_assign_then_load', 'assigned');
        Observer.Expect('amount_after_assign_then_load', '0');
        Observer.Expect('name_after_load_with_missing_key', '[]');
        Observer.Expect('name_after_get_assign_load', 'changed');
        Observer.Expect('amount_after_get_assign_load', '7');
        Observer.Verify();
    end;

    [Test]
    procedure LoadFields_AsBooleanFunction()
    var
        Row: Record "PY Row";
        Other: Record "PY Row";
        Ok: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Other.Id := 5;
        Other.Name := 'stored';
        Other.Insert();
        Row.Id := 5;
        Ok := Row.LoadFields(Name);
        Observer.Observe('result_with_existing_key', Format(Ok));
        Clear(Row);
        Row.Id := 77;
        Ok := Row.LoadFields(Name);
        Observer.Observe('result_with_missing_key', Format(Ok));
        Observer.Expect('result_with_existing_key', 'No');
        Observer.Expect('result_with_missing_key', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Find_DirectionCharacters_Orders()
    var
        Row: Record "PY Row";
        Observer: Codeunit "Probe Observer";
        Which: Text;
        Orders: List of [Text];
        Result: Text;
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 3;
        Row.Insert();
        Row.Id := 5;
        Row.Insert();
        Orders.Add('=');
        Orders.Add('=><');
        Orders.Add('=<>');
        Orders.Add('<=>');
        Orders.Add('><=');
        Orders.Add('<>=');
        Orders.Add('>=<');
        Orders.Add('<=');
        Orders.Add('>=');
        Orders.Add('<>');
        Orders.Add('><');
        foreach Which in Orders do begin
            Result := '';
            Row.Id := 3;
            Result += 'present3:' + Format(Row.Find(Which)) + '/' + Format(Row.Id) + ' ';
            Row.Id := 4;
            Result += 'absent4:' + Format(Row.Find(Which)) + '/' + Format(Row.Id) + ' ';
            Row.Id := 0;
            Result += 'absent0:' + Format(Row.Find(Which)) + '/' + Format(Row.Id) + ' ';
            Row.Id := 9;
            Result += 'absent9:' + Format(Row.Find(Which)) + '/' + Format(Row.Id);
            Observer.Observe('find_' + Which, Result);
        end;
        Observer.Expect('find_=', 'present3:Yes/3 absent4:No/4 absent0:No/0 absent9:No/9');
        Observer.Expect('find_=><', 'present3:Yes/3 absent4:Yes/5 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_=<>', 'present3:Yes/3 absent4:Yes/3 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_<=>', 'present3:Yes/1 absent4:Yes/3 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_><=', 'present3:Yes/5 absent4:Yes/5 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_<>=', 'present3:Yes/1 absent4:Yes/3 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_>=<', 'present3:Yes/5 absent4:Yes/5 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_<=', 'present3:Yes/1 absent4:Yes/3 absent0:No/0 absent9:Yes/5');
        Observer.Expect('find_>=', 'present3:Yes/5 absent4:Yes/5 absent0:Yes/1 absent9:No/9');
        Observer.Expect('find_<>', 'present3:Yes/1 absent4:Yes/3 absent0:Yes/1 absent9:Yes/5');
        Observer.Expect('find_><', 'present3:Yes/5 absent4:Yes/5 absent0:Yes/1 absent9:Yes/5');
        Observer.Verify();
    end;
}
