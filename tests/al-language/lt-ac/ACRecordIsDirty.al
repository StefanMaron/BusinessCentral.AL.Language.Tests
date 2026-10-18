// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: Record.IsDirty() (BC 29 and later; BC 27 and 28 reject it, see must-not-compile case 0960). Settles #626 item 8.
// BC versions: 29

#if BC29PLUS
table 77504 "LT AC Dirty Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 77504 "LT AC Record Is Dirty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_IsDirty_Lifecycle()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Dirty Row";
        Other: Record "LT AC Dirty Row";
    begin
        Row.DeleteAll();
        Observer.Observe('fresh', Format(Row.IsDirty()));
        Row.Init();
        Observer.Observe('after_init', Format(Row.IsDirty()));
        Row.Id := 1;
        Row.Name := 'one';
        Observer.Observe('after_assign_before_insert', Format(Row.IsDirty()));
        Row.Insert();
        Observer.Observe('after_insert', Format(Row.IsDirty()));
        Row.Get(1);
        Observer.Observe('after_get', Format(Row.IsDirty()));
        Row.Name := 'changed';
        Observer.Observe('after_assign', Format(Row.IsDirty()));
        Row.Modify();
        Observer.Observe('after_modify', Format(Row.IsDirty()));
        Row.Name := 'changed';
        Observer.Observe('after_same_value', Format(Row.IsDirty()));
        Row.Name := 'again';
        Row.Name := 'changed';
        Observer.Observe('after_value_restored', Format(Row.IsDirty()));
        Row.Amount := 5;
        Observer.Observe('after_second_field', Format(Row.IsDirty()));
        Row.Get(1);
        Observer.Observe('after_get_again', Format(Row.IsDirty()));
        Row.Validate(Name, 'validated');
        Observer.Observe('after_validate', Format(Row.IsDirty()));
        Other := Row;
        Observer.Observe('copy_dirty', Format(Other.IsDirty()));
        Row.Get(1);
        Other.Init();
        Other.TransferFields(Row);
        Observer.Observe('after_transferfields', Format(Other.IsDirty()));
        Row.Get(1);
        Row.Delete();
        Observer.Observe('after_delete', Format(Row.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure AC_IsDirty_FindAndRename()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Dirty Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'b';
        Row.Insert();
        Row.FindFirst();
        Observer.Observe('after_findfirst', Format(Row.IsDirty()));
        Row.Name := 'x';
        Observer.Observe('assigned', Format(Row.IsDirty()));
        Row.FindLast();
        Observer.Observe('after_findlast', Format(Row.IsDirty()));
        Row.Rename(3);
        Observer.Observe('after_rename', Format(Row.IsDirty()));
        Row.Name := 'y';
        Row.Reset();
        Observer.Observe('after_reset', Format(Row.IsDirty()));
        Row.Init();
        Observer.Observe('after_init_again', Format(Row.IsDirty()));
        Observer.Finish();
    end;
}
#endif
