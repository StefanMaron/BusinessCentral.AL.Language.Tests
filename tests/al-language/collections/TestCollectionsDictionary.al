// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type
// Scope: in-scope
// Fixtures used: none (self-contained)
// Note: regression pin for AL Dictionary semantics, covering a Dictionary that
// exists only as a method local (never a field/property) as well as a global
// field, and both Text/Integer and Text/Text closed instantiations.
// BC versions: 24+

codeunit 60219 "Test Collections Dictionary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        GlobalDict: Dictionary of [Text, Integer];

    [Test]
    procedure DictAsMethodLocal_StoresAndRetrievesValues()
    var
        LocalDict: Dictionary of [Text, Integer];
        Got: Integer;
    begin
        Initialize();
        // A Dictionary that exists ONLY as a method local — never a field, never a
        // property — so nothing can discover its closed instantiation by scanning types.
        LocalDict.Add('alpha', 11);
        LocalDict.Add('beta', 22);

        Assert.AreEqual(2, LocalDict.Count(), 'both entries should be present');

        LocalDict.Get('alpha', Got);
        Assert.AreEqual(11, Got, 'value stored under alpha');

        LocalDict.Get('beta', Got);
        Assert.AreEqual(22, Got, 'value stored under beta');

        Assert.IsTrue(LocalDict.ContainsKey('alpha'), 'alpha was added');
        Assert.IsFalse(LocalDict.ContainsKey('gamma'), 'gamma was never added');
    end;

    [Test]
    procedure DictAsMethodLocal_GetOnMissingKeyErrors()
    var
        LocalDict: Dictionary of [Text, Integer];
        Got: Integer;
    begin
        Initialize();
        LocalDict.Add('alpha', 11);

        // Negative direction: the dictionary must behave like a real dictionary, not
        // like a silently-empty stand-in that returns a default for every key.
        asserterror LocalDict.Get('missing', Got);
        Assert.AreEqual('The given key was not present in the dictionary.', GetLastErrorText(),
            'Get on an absent key must raise BC''s real key-not-found error');
    end;

    [Test]
    procedure DictAsMethodLocal_RemoveDropsTheEntry()
    var
        LocalDict: Dictionary of [Text, Integer];
    begin
        Initialize();
        LocalDict.Add('alpha', 11);
        LocalDict.Add('beta', 22);

        Assert.IsTrue(LocalDict.Remove('alpha'), 'removing a present key reports true');
        Assert.AreEqual(1, LocalDict.Count(), 'one entry left after the remove');
        Assert.IsFalse(LocalDict.ContainsKey('alpha'), 'alpha is gone');
        Assert.IsTrue(LocalDict.ContainsKey('beta'), 'beta survived');

        Assert.IsFalse(LocalDict.Remove('alpha'), 'removing an absent key reports false');
    end;

    [Test]
    procedure DictAsGlobal_StoresAndRetrievesValues()
    var
        Got: Integer;
    begin
        Initialize();
        // Control case: a Dictionary reachable as a FIELD.
        GlobalDict.Add('one', 1);
        GlobalDict.Add('two', 2);

        Assert.AreEqual(2, GlobalDict.Count(), 'both entries should be present');

        GlobalDict.Get('two', Got);
        Assert.AreEqual(2, Got, 'value stored under two');
    end;

    [Test]
    procedure DictOfTextText_AlsoWorks()
    var
        TextDict: Dictionary of [Text, Text];
        Got: Text;
    begin
        Initialize();
        // A different closed instantiation.
        TextDict.Add('k', 'v');

        Assert.AreEqual(1, TextDict.Count(), 'one entry');
        TextDict.Get('k', Got);
        Assert.AreEqual('v', Got, 'value stored under k');
    end;

    local procedure Initialize()
    begin
        Clear(GlobalDict);
    end;
}
