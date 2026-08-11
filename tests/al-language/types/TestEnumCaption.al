// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/format-method
// Scope: in-scope
// Fixtures: ALT Caption Kind enum (60910): None(0)/'None', ArchivedRecord(1)/'Archived Item',
//   NoCaptionDeclared(2)/no Caption property at all.
//
// Format(<enum value>) must return the value's declared Caption, not its AL member
// (identifier) name. When a value declares no Caption at all, AL's documented default
// applies: the caption falls back to the member name itself.

codeunit 60947 "Test Enum Caption"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Enum_Format_ExplicitCaption_ReturnsCaptionNotName()
    var
        K: Enum "ALT Caption Kind";
    begin
        Initialize();
        K := "ALT Caption Kind"::ArchivedRecord;
        Assert.AreEqual('Archived Item', Format(K),
            'Format(enum) must return the declared Caption (''Archived Item''), not the member name (''ArchivedRecord'')');
    end;

    [Test]
    procedure Enum_Format_NoDeclaredCaption_FallsBackToMemberName()
    var
        K: Enum "ALT Caption Kind";
    begin
        Initialize();
        K := "ALT Caption Kind"::NoCaptionDeclared;
        Assert.AreEqual('NoCaptionDeclared', Format(K),
            'Format(enum) for a value with no declared Caption must fall back to the member name');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
