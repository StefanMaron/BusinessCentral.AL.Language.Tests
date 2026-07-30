// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-get-method
// Scope: in-scope
// Fixtures used: none
//
// Trappable collection errors must surface BC's real error text
// ("An invalid argument was passed to a 'List' data type method.") for both the
// value-returning and by-var forms of List.Get, on both empty and out-of-range access.

codeunit 60381 "Test List Trappable Error"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Negative: empty list, out-of-range index -> BC's real error text.
    // The two-arg Get(index, var) form routes through a different error-handling path
    // than the value-returning form — pinned separately so a fix to one cannot hide a
    // gap in the other.
    [Test]
    procedure List_EmptyListGetVar_SurfacesRealOutOfRangeError()
    var
        L: List of [Integer];
        V: Integer;
    begin
        Initialize();

        asserterror L.Get(5, V);
        Assert.ExpectedError('An invalid argument was passed to a ''List'' data type method.');
    end;

    // The value-returning Get form must surface the same real error text as the by-var
    // form above.
    [Test]
    procedure List_EmptyListGet_SurfacesRealOutOfRangeError()
    var
        L: List of [Integer];
        V: Integer;
    begin
        Initialize();

        asserterror V := L.Get(5);
        Assert.ExpectedError('An invalid argument was passed to a ''List'' data type method.');
    end;

    // Positive: in-range Get still returns the real value (the error-path fix must not
    // perturb the success path).
    [Test]
    procedure List_Get_InRange_ReturnsValue()
    var
        L: List of [Integer];
    begin
        Initialize();

        L.Add(11);
        L.Add(22);
        Assert.AreEqual(22, L.Get(2), 'L.Get(2) must return the second element');
    end;

    local procedure Initialize()
    begin
        // No persistent tables used — every List here is a local variable.
    end;
}
