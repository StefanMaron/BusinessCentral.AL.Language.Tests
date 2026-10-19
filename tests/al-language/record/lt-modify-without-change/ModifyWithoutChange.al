// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own table 74971, log 74972, test codeunit 74973
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Modify() on a record with no field changed: whether SystemRowVersion changes (in the variable after the call and when the row is read again), whether the OnModify trigger runs, and whether xRec equals Rec in it; Modify(true), Modify(false) and ModifyAll with the same value; Modify with one field changed. Row versions are compared with each other, never asserted as numbers. ModifyAll with the same value is asserted for its trace only: whether it changes the row version differs between the local container (unchanged) and the CI container (changed), so the row version is not asserted for it.
// BC versions: 29 (27 and 28 by CI)

table 74971 "LT MW Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }

    trigger OnModify()
    var
        L: Codeunit "LT MW Log";
    begin
        L.Add('OnModify rec=' + Rec.Name + '/' + Format(Rec.Qty) + ' xrec=' + xRec.Name + '/' + Format(xRec.Qty));
    end;
}

codeunit 74972 "LT MW Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

codeunit 74973 "LT Modify Without Change"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT MW Row";
        Other: Record "LT MW Row";
    begin
        Row.DeleteAll();
        Row.Id := 1; Row.Name := 'one'; Row.Qty := 5; Row.Insert();
        Other.Id := 2; Other.Name := 'two'; Other.Qty := 6; Other.Insert();
    end;

    local procedure Version(Id: Integer): BigInteger
    var
        Row: Record "LT MW Row";
    begin
        Row.Get(Id);
        exit(Row.SystemRowVersion);
    end;

    [Test]
    procedure Modify_NoFieldChanged_RowVersionAndTrigger()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Modify();
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('db_version_greater', Format(Version(1) > Before));
        Observer.Observe('var_version_same', Format(Row.SystemRowVersion = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('db_version_greater', 'No');
        Observer.Expect('var_version_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTriggerTrue_NoFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Modify(true);
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('trace', 'OnModify rec=one/5 xrec=one/5;');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTriggerFalse_NoFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Modify(false);
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_FieldAssignedSameValue()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Name := 'one';
        Row.Qty := 5;
        Row.Modify();
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_OneFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Other: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        Other := Version(2);
        L.Take();
        Row.Get(1);
        Row.Qty := 7;
        Row.Modify();
        Observer.Observe('db_version_same', Format(Version(1) = Before));
        Observer.Observe('db_version_greater', Format(Version(1) > Before));
        Observer.Observe('var_version_equals_db', Format(Row.SystemRowVersion = Version(1)));
        Observer.Observe('other_row_same', Format(Version(2) = Other));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_same', 'No');
        Observer.Expect('db_version_greater', 'Yes');
        Observer.Expect('var_version_equals_db', 'Yes');
        Observer.Expect('other_row_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_TwiceWithoutChange_AfterRealChange()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Changed: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Row.Get(1);
        Row.Qty := 7;
        Row.Modify();
        Changed := Version(1);
        L.Take();
        Row.Modify();
        Observer.Observe('second_modify_same', Format(Version(1) = Changed));
        Row.Get(1);
        Row.Modify();
        Observer.Observe('reread_modify_same', Format(Version(1) = Changed));
        Observer.Observe('trace', L.Take());
        Observer.Expect('second_modify_same', 'Yes');
        Observer.Expect('reread_modify_same', 'Yes');
        Observer.Expect('trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_SameValue_And_NewValue()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before1: BigInteger;
        Before2: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before1 := Version(1);
        Before2 := Version(2);
        L.Take();
        Row.SetRange(Id, 1);
        Row.ModifyAll(Qty, 5);
        Observer.Observe('same_value_trace', L.Take());
        Row.ModifyAll(Qty, 5, true);
        Observer.Observe('same_value_trigger_trace', L.Take());
        Row.ModifyAll(Qty, 9);
        Observer.Observe('new_value_row1_same', Format(Version(1) = Before1));
        Observer.Observe('new_value_row2_same', Format(Version(2) = Before2));
        Observer.Observe('new_value_trace', L.Take());
        Observer.Expect('same_value_trace', '');
        Observer.Expect('same_value_trigger_trace', 'OnModify rec=one/5 xrec=one/5;');
        Observer.Expect('new_value_row1_same', 'No');
        Observer.Expect('new_value_row2_same', 'Yes');
        Observer.Expect('new_value_trace', '');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_RunTriggerTrue_OneFieldChanged()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before := Version(1);
        L.Take();
        Row.Get(1);
        Row.Qty := 7;
        Row.Modify(true);
        Observer.Observe('db_version_greater', Format(Version(1) > Before));
        Observer.Observe('trace', L.Take());
        Observer.Expect('db_version_greater', 'Yes');
        Observer.Expect('trace', 'OnModify rec=one/7 xrec=one/7;');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_NewValue_RunTriggerTrue()
    var
        Row: Record "LT MW Row";
        L: Codeunit "LT MW Log";
        Before1: BigInteger;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Before1 := Version(1);
        L.Take();
        Row.SetRange(Id, 1);
        Row.ModifyAll(Qty, 9, true);
        Observer.Observe('row1_greater', Format(Version(1) > Before1));
        Observer.Observe('trace', L.Take());
        Observer.Expect('row1_greater', 'Yes');
        Observer.Expect('trace', 'OnModify rec=one/9 xrec=one/9;');
        Observer.Verify();
    end;
}
