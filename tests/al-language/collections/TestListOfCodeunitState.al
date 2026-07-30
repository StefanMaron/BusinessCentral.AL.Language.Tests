// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: "List Codeunit State Stateful" (60379)
//
// A codeunit instance added to a `List of [Codeunit]` in a callee scope must be
// retrieved in the caller scope with its instance state intact.

codeunit 60380 "Test List Of Codeunit State"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure BuildList(var Result: List of [Codeunit "List Codeunit State Stateful"])
    var
        C: Codeunit "List Codeunit State Stateful";
    begin
        C.SetValue(42);
        Result.Add(C);
    end;

    // The shape that matters: list populated in a callee, consumed in the caller.
    [Test]
    procedure List_CalleeScopeAdd_CallerScopeGet_StateRoundTrips()
    var
        L: List of [Codeunit "List Codeunit State Stateful"];
        C: Codeunit "List Codeunit State Stateful";
    begin
        Initialize();

        BuildList(L);
        Assert.AreEqual(1, L.Count(), 'List built in callee scope must have 1 element');
        L.Get(1, C);
        Assert.AreEqual(42, C.GetValue(), 'Codeunit state set in callee scope must round-trip through the list');
    end;

    // Discriminator: Add + Get within ONE scope.
    [Test]
    procedure List_SameScopeAddGet_StateRoundTrips()
    var
        L: List of [Codeunit "List Codeunit State Stateful"];
        C: Codeunit "List Codeunit State Stateful";
        C2: Codeunit "List Codeunit State Stateful";
    begin
        Initialize();

        C.SetValue(7);
        L.Add(C);
        L.Get(1, C2);
        Assert.AreEqual(7, C2.GetValue(), 'Codeunit state must round-trip through same-scope Add+Get');
    end;

    local procedure Initialize()
    begin
        // No persistent tables used — state lives entirely in codeunit instances.
    end;
}
