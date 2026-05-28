// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope (Cloud-compatible, multi-app fixture required)
// Fixtures used: ALT Internal Table Ext (60205) on ALT Internal Table (61001)
// BC versions: 27.5+
//
// CLAIM: a dependent app can read and write fields that a dependency app's
// tableextension added to an internal fixture table. This exercises the
// symbol-merge of a tableextension loaded as a compiled .app dependency.

codeunit 60203 "Test TableExt Cross App"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Field round-trip ─────────────────────────────────────────────────────

    [Test]
    procedure TableExt_CrossApp_FooField_InsertAndGet_RoundTrips()
    // CLAIM: "ALT Foo" (Integer) added by the fixture app's tableextension persists
    // through Insert and is readable via Get from the dependent test app.
    // DOCS: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
    var
        InternalRec: Record "ALT Internal Table";
        EntryNo: Integer;
    begin
        Initialize();
        InternalRec."Value" := 42;
        InternalRec."ALT Foo" := 42;
        InternalRec.Insert(false);
        EntryNo := InternalRec."Entry No.";

        Clear(InternalRec);
        InternalRec.Get(EntryNo);
        Assert.AreEqual(42, InternalRec."ALT Foo", 'ALT Foo must round-trip through Insert/Get');
    end;

    [Test]
    procedure TableExt_CrossApp_BothFields_PersistAfterModify()
    // CLAIM: both extension fields ("ALT Foo" and "ALT Bar") persist correctly
    // after a Modify — proves that multiple extension fields all survive the update path.
    var
        InternalRec: Record "ALT Internal Table";
        EntryNo: Integer;
    begin
        Initialize();
        InternalRec."Value" := 1;
        InternalRec."ALT Foo" := 1;
        InternalRec."ALT Bar" := 'initial';
        InternalRec.Insert(false);
        EntryNo := InternalRec."Entry No.";

        InternalRec."ALT Foo" := 99;
        InternalRec."ALT Bar" := 'modified';
        InternalRec.Modify(false);

        Clear(InternalRec);
        InternalRec.Get(EntryNo);
        Assert.AreEqual(99, InternalRec."ALT Foo", 'ALT Foo must reflect modified value');
        Assert.AreEqual('modified', InternalRec."ALT Bar", 'ALT Bar must reflect modified value');
    end;

    [Test]
    procedure TableExt_CrossApp_SetRange_OnExtField_FiltersRecords()
    // CLAIM: SetRange on "ALT Foo" (an extension field) narrows the result set,
    // proving filters on extension fields work in the dependent app.
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Initialize();
        InternalRec."Value" := 10;
        InternalRec."ALT Foo" := 10;
        InternalRec.Insert(false);

        Clear(InternalRec);
        InternalRec."Value" := 20;
        InternalRec."ALT Foo" := 20;
        InternalRec.Insert(false);

        InternalRec.Reset();
        InternalRec.SetRange("ALT Foo", 10, 10);
        Assert.AreEqual(1, InternalRec.Count(), 'SetRange on ALT Foo must filter to exactly one record');
    end;

    [Test]
    procedure TableExt_CrossApp_Insert_AssignsAutoIncrementEntryNo()
    // CLAIM: inserting a record on the internal fixture table assigns a non-zero
    // auto-incremented primary key, proving the fixture table and extension are live.
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Initialize();
        InternalRec."Value" := 5;
        InternalRec."ALT Foo" := 5;
        InternalRec.Insert(false);

        Assert.AreNotEqual(0, InternalRec."Entry No.", 'Auto-increment must assign a non-zero Entry No.');
    end;

    local procedure Initialize()
    var
        InternalRec: Record "ALT Internal Table";
    begin
        Cleanup.Initialize();
        InternalRec.DeleteAll(false);
    end;
}
