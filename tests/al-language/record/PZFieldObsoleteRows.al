// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-obsoletestate-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160), ALT ObsoleteState Fixture (60984); self-contained codeunit 69351
// Probe: written against a real BC 29.0 service tier (29.0.54011.55816); every literal below is what that tier produced. Other BC versions are checked by the CI matrix.
//
// The Field table rows of a Live, a Pending and a Removed field of one table (record/TestFieldObsoleteStateFixture.Table.al): all three have a row, Enabled Yes, Class Normal and the same
// Type, Len, Type Name, SQL data type and Data Classification; only ObsoleteState and ObsoleteReason differ. Counts of the own fields (numbers 1 to 100) by Enabled, ObsoleteState, Class and Type.
// Only columns 1 to 28 are read (later columns differ between BC versions); system fields are left out of the counts.
// BC versions: 29.0
codeunit 69351 "PZ Field Obsolete Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ValueOf(FieldNo: Integer; ColumnNo: Integer): Text
    var
        RecRef: RecordRef;
        Row: Record Field;
    begin
        Row.Get(Database::"ALT ObsoleteState Fixture", FieldNo);
        RecRef.GetTable(Row);
        exit(Format(RecRef.Field(ColumnNo).Value()));
    end;

    [Test]
    procedure FieldRows_AllColumns_OfLivePendingAndRemovedField()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::Field);
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            if FldRef.Number() <= 28 then
                Observer.Observe('column ' + Format(FldRef.Number()) + ' ' + FldRef.Name(), ValueOf(2, FldRef.Number()) + ' | ' + ValueOf(3, FldRef.Number()) + ' | ' + ValueOf(4, FldRef.Number()));
        end;
        Observer.Expect('column 1 TableNo', '60984 | 60984 | 60984');
        Observer.Expect('column 2 No.', '2 | 3 | 4');
        Observer.Expect('column 3 TableName', 'ALT ObsoleteState Fixture | ALT ObsoleteState Fixture | ALT ObsoleteState Fixture');
        Observer.Expect('column 4 FieldName', 'Live Field | Pending Field | Removed Field');
        Observer.Expect('column 5 Type', 'Text | Text | Text');
        Observer.Expect('column 6 Len', '30 | 30 | 30');
        Observer.Expect('column 7 Class', 'Normal | Normal | Normal');
        Observer.Expect('column 8 Enabled', 'Yes | Yes | Yes');
        Observer.Expect('column 9 Type Name', 'Text30 | Text30 | Text30');
        Observer.Expect('column 10 ExternalName', ' |  | ');
        Observer.Expect('column 20 Field Caption', 'Live Field | Pending Field | Removed Field');
        Observer.Expect('column 21 RelationTableNo', '0 | 0 | 0');
        Observer.Expect('column 22 RelationFieldNo', '0 | 0 | 0');
        Observer.Expect('column 23 SQLDataType', 'Varchar | Varchar | Varchar');
        Observer.Expect('column 24 OptionString', ' |  | ');
        Observer.Expect('column 25 ObsoleteState', 'No | Pending | Removed');
        Observer.Expect('column 26 ObsoleteReason', ' | pending in fixture | removed in fixture');
        Observer.Expect('column 27 DataClassification', 'CustomerContent | CustomerContent | CustomerContent');
        Observer.Expect('column 28 IsPartOfPrimaryKey', 'No | No | No');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRows_CountsOfTheTable_ByState()
    var
        Row: Record Field;
        Observer: Codeunit "Probe Observer";
    begin
        Row.SetRange(TableNo, Database::"ALT ObsoleteState Fixture");
        Row.SetRange("No.", 1, 100);
        Observer.Observe('all rows', Format(Row.Count()));
        Row.SetRange(Enabled, true);
        Observer.Observe('enabled rows', Format(Row.Count()));
        Row.SetRange(Enabled);
        Row.SetFilter(ObsoleteState, '<>%1', Row.ObsoleteState::No);
        Observer.Observe('obsolete (pending or removed) rows', Format(Row.Count()));
        Row.SetRange(ObsoleteState, Row.ObsoleteState::Pending);
        Observer.Observe('pending rows', Format(Row.Count()));
        Row.SetRange(ObsoleteState);
        Row.SetRange(Class, Row.Class::Normal);
        Observer.Observe('normal class rows', Format(Row.Count()));
        Row.SetRange(Class);
        Row.SetRange(Type, Row.Type::Text);
        Observer.Observe('text rows', Format(Row.Count()));
        Row.SetRange(Type);
        Row.SetRange("No.", 3, 100);
        Row.FindFirst();
        Observer.Observe('first row with no. 3 or more', Format(Row."No."));
        Observer.Expect('all rows', '4');
        Observer.Expect('enabled rows', '4');
        Observer.Expect('obsolete (pending or removed) rows', '2');
        Observer.Expect('pending rows', '1');
        Observer.Expect('normal class rows', '4');
        Observer.Expect('text rows', '3');
        Observer.Expect('first row with no. 3 or more', '3');
        Observer.Verify();
    end;
}
