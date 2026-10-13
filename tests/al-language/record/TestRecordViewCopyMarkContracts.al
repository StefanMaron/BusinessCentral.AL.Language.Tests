// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copy-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setview-method
// Scope: in-scope
// Fixtures used: ALT Keyed (60006), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins SetRecFilter with other filters set, what Copy carries over (buffer, filters of every group,
// key, direction) and when Copy(.., true) is refused, what Mark returns, and how SetView replaces the
// view and rejects garbage.
// BC versions: 27.5

codeunit 68211 "Probe Record View Copy Mark"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        Cleanup.Initialize();
        ALTKeyed.Init();
        ALTKeyed."Entry No." := 1;
        ALTKeyed.Name := 'a';
        ALTKeyed.Amount := 5;
        ALTKeyed.Insert();
        ALTKeyed.Init();
        ALTKeyed."Entry No." := 2;
        ALTKeyed.Name := 'b';
        ALTKeyed.Amount := 6;
        ALTKeyed.Insert();
        Commit();
    end;

    [Test]
    procedure SetRecFilter_KeepsFiltersOnOtherFields_AndFiltersOnThePrimaryKey()
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        Initialize();
        ALTKeyed.Get(1);
        ALTKeyed.SetRange(Name, 'zzz');

        ALTKeyed.SetRecFilter();

        Assert.AreEqual('Entry No.: 1, Name: zzz', ALTKeyed.GetFilters(), 'filters');
        Assert.AreEqual(0, ALTKeyed.Count(), 'both filters apply');

        ALTKeyed.Reset();
        ALTKeyed.SetRange(Amount, 5);
        ALTKeyed.Get(2);
        ALTKeyed.SetRecFilter();
        Assert.AreEqual('Entry No.: 2, Amount: 5', ALTKeyed.GetFilters(), 'the filter on a non-key field stays');
    end;

    [Test]
    procedure Copy_CarriesBufferFiltersOfAllGroupsKeyAndDirection()
    var
        ALTKeyed: Record "ALT Keyed";
        Copied: Record "ALT Keyed";
    begin
        Initialize();
        ALTKeyed.SetCurrentKey(Amount);
        ALTKeyed.Ascending(false);
        ALTKeyed.SetRange("Entry No.", 1, 2);
        ALTKeyed.FilterGroup(2);
        ALTKeyed.SetRange(Name, 'a');
        ALTKeyed.FilterGroup(0);
        ALTKeyed.Get(1);

        Copied.Copy(ALTKeyed);

        Assert.AreEqual('Entry No.: 1..2', Copied.GetFilters(), 'group 0 filters');
        Assert.AreEqual('Amount', Copied.CurrentKey(), 'key');
        Assert.IsFalse(Copied.Ascending(), 'direction');
        Assert.AreEqual(1, Copied."Entry No.", 'buffer');
        Copied.FilterGroup(2);
        Assert.AreEqual('Name: a', Copied.GetFilters(), 'group 2 filters');
        Copied.FilterGroup(0);
        Assert.AreEqual(0, Copied.FilterGroup(), 'the current group is 0');
    end;

    [Test]
    procedure Copy_ShareTable_RequiresBothRecordsToBeTemporary()
    var
        ALTKeyed: Record "ALT Keyed";
        Temporary: Record "ALT Keyed" temporary;
        Copied: Record "ALT Keyed";
    begin
        Initialize();
        Temporary.Init();
        Temporary."Entry No." := 99;
        Temporary.Insert();

        asserterror Temporary.Copy(ALTKeyed, true);
        Assert.AreEqual('The COPY function can only be used with the shareTable argument set to true if both records are temporary.', GetLastErrorText(), 'real onto temporary');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'code');

        asserterror Copied.Copy(Temporary, true);
        Assert.AreEqual('The COPY function can only be used with the shareTable argument set to true if both records are temporary.', GetLastErrorText(), 'temporary onto real');

        Copied.Copy(Temporary);
        Assert.IsFalse(Copied.IsTemporary(), 'a plain Copy of a temporary record onto a real one copies values and filters only');
        Assert.AreEqual(2, Copied.Count(), 'and reads the real table');
    end;

    [Test]
    procedure Mark_ReturnsTheNewState()
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        Initialize();
        ALTKeyed.Get(1);

        Assert.IsTrue(ALTKeyed.Mark(true), 'Mark(true)');
        Assert.IsTrue(ALTKeyed.Mark(true), 'Mark(true) again');
        Assert.IsFalse(ALTKeyed.Mark(false), 'Mark(false)');
        Assert.IsFalse(ALTKeyed.Mark(), 'the getter');
        ALTKeyed.Reset();
        ALTKeyed.MarkedOnly(true);
        Assert.AreEqual(0, ALTKeyed.Count(), 'no row is marked');
    end;

    [Test]
    procedure SetView_ReplacesTheFilters_KeepsTheDirection_AndRejectsGarbage()
    var
        ALTKeyed: Record "ALT Keyed";
        Cr: Text[1];
    begin
        Initialize();
        Cr[1] := 13;

        ALTKeyed.SetView('SORTING(Amount) ORDER(Descending) WHERE(Entry No.=FILTER(1..2))');
        Assert.AreEqual('VERSION(1) SORTING(Amount) ORDER(Descending) WHERE(Entry No.=FILTER(1..2))', ALTKeyed.GetView(), 'round trip');

        ALTKeyed.SetRange(Name, 'a');
        ALTKeyed.SetView('WHERE(Amount=FILTER(6))');
        Assert.AreEqual('Amount: 6', ALTKeyed.GetFilters(), 'the earlier filters are gone');
        Assert.AreEqual('VERSION(1) SORTING(Entry No.) ORDER(Descending) WHERE(Amount=FILTER(6))', ALTKeyed.GetView(), 'the key is the primary key again; the descending order stays');

        asserterror ALTKeyed.SetView('GARBAGE(');
        Assert.AreEqual('Invalid expression of type: table view.' + Cr + '\' + 'GARBAGE(', GetLastErrorText(), 'text');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'code');
    end;
}
