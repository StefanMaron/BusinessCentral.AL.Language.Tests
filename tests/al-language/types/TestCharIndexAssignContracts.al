// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 69065
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins assigning a character into a position of a Code or Text variable:
//  - Code[1]: Letter[1] := 'a' gives 'A' (a Code converts to upper case); Letter[1] := 65 gives 'A';
//  - Code[10] holding ABCDE: Ten[3] := 'z' gives ABZDE; Text[5] holding hello: Txt[1] := 'J' gives Jello.
// BC versions: 27.5

codeunit 69065 "Probe Char Index Assign"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CharacterAssignedIntoAPosition()
    var
        Letter: Code[1];
        Ten: Code[10];
        Txt: Text[5];
    begin
        Letter[1] := 'a';
        Assert.AreEqual('A', Letter, 'Code[1] from a lower case literal');
        Clear(Letter);
        Letter[1] := 65;
        Assert.AreEqual('A', Letter, 'Code[1] from a number');

        Ten := 'ABCDE';
        Ten[3] := 'z';
        Assert.AreEqual('ABZDE', Ten, 'Code[10] position 3');

        Txt := 'hello';
        Txt[1] := 'J';
        Assert.AreEqual('Jello', Txt, 'Text[5] position 1');
    end;
}
