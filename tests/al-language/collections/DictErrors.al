// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74621
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Dictionary error paths: duplicate key Add, Get of a missing key, error text and code per key type.
// BC versions: 29 (27 and 28 by CI)

codeunit 74621 "LT ClT Dict Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Err_TextKey()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        V: Integer;
    begin
        D.Add('a', 1);
        asserterror D.Add('a', 2);
        Observer.ObserveError('add duplicate');
        Observer.Observe('value unchanged', Format(D.Get('a')));
        asserterror V := D.Get('zzz');
        Observer.ObserveError('get missing');
        asserterror V := D.Get('');
        Observer.ObserveError('get empty key');
        D.Add('A', 2);
        Observer.Observe('add duplicate other case', 'no error');
        Observer.Observe('count', Format(D.Count()));
        Observer.Expect('add duplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('add duplicate|code', 'Argument');
        Observer.Expect('value unchanged', '1');
        Observer.Expect('get missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('get missing|code', 'KeyNotFound');
        Observer.Expect('get empty key|text', 'The given key was not present in the dictionary.');
        Observer.Expect('get empty key|code', 'KeyNotFound');
        Observer.Expect('add duplicate other case', 'no error');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Err_IntegerKey()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Integer, Text];
        V: Text;
    begin
        D.Add(1, 'a');
        asserterror D.Add(1, 'b');
        Observer.ObserveError('add duplicate');
        asserterror V := D.Get(2);
        Observer.ObserveError('get missing');
        asserterror V := D.Get(-1);
        Observer.ObserveError('get negative');
        asserterror V := D.Get(0);
        Observer.ObserveError('get 0');
        Observer.Expect('add duplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('add duplicate|code', 'Argument');
        Observer.Expect('get missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('get missing|code', 'KeyNotFound');
        Observer.Expect('get negative|text', 'The given key was not present in the dictionary.');
        Observer.Expect('get negative|code', 'KeyNotFound');
        Observer.Expect('get 0|text', 'The given key was not present in the dictionary.');
        Observer.Expect('get 0|code', 'KeyNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Err_OtherKeyTypes()
    var
        Observer: Codeunit "Probe Observer";
        DD: Dictionary of [Decimal, Integer];
        DB: Dictionary of [Boolean, Integer];
        DDt: Dictionary of [Date, Integer];
        DE: Dictionary of [Enum "LT ClT Color", Integer];
        DC: Dictionary of [Code[10], Integer];
        V: Integer;
    begin
        asserterror V := DD.Get(1.5);
        Observer.ObserveError('decimal missing');
        asserterror V := DB.Get(true);
        Observer.ObserveError('boolean missing');
        asserterror V := DDt.Get(DMY2Date(1, 1, 2020));
        Observer.ObserveError('date missing');
        asserterror V := DE.Get(Enum::"LT ClT Color"::Blue);
        Observer.ObserveError('enum missing');
        asserterror V := DC.Get('abc');
        Observer.ObserveError('code missing');
        DD.Add(1.5, 1);
        asserterror DD.Add(1.5, 2);
        Observer.ObserveError('decimal duplicate');
        DE.Add(Enum::"LT ClT Color"::Blue, 1);
        asserterror DE.Add(Enum::"LT ClT Color"::Blue, 2);
        Observer.ObserveError('enum duplicate');
        DC.Add('abc', 1);
        asserterror DC.Add('ABC', 2);
        Observer.ObserveError('code duplicate other case');
        DDt.Add(0D, 1);
        asserterror DDt.Add(0D, 2);
        Observer.ObserveError('date duplicate');
        Observer.Expect('decimal missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('decimal missing|code', 'KeyNotFound');
        Observer.Expect('boolean missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('boolean missing|code', 'KeyNotFound');
        Observer.Expect('date missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('date missing|code', 'KeyNotFound');
        Observer.Expect('enum missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('enum missing|code', 'KeyNotFound');
        Observer.Expect('code missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('code missing|code', 'KeyNotFound');
        Observer.Expect('decimal duplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('decimal duplicate|code', 'Argument');
        Observer.Expect('enum duplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('enum duplicate|code', 'Argument');
        Observer.Expect('code duplicate other case|text', 'An item with the same key has already been added.');
        Observer.Expect('code duplicate other case|code', 'Argument');
        Observer.Expect('date duplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('date duplicate|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Err_GuidAndTimeKeys()
    var
        Observer: Codeunit "Probe Observer";
        DG: Dictionary of [Guid, Integer];
        DT: Dictionary of [Time, Integer];
        DDT: Dictionary of [DateTime, Integer];
        DCh: Dictionary of [Char, Integer];
        G: Guid;
        C: Char;
        V: Integer;
    begin
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        asserterror V := DG.Get(G);
        Observer.ObserveError('guid missing');
        DG.Add(G, 1);
        asserterror DG.Add(G, 2);
        Observer.ObserveError('guid duplicate');
        asserterror V := DT.Get(120000T);
        Observer.ObserveError('time missing');
        asserterror V := DDT.Get(0DT);
        Observer.ObserveError('datetime missing');
        C := 'a';
        asserterror V := DCh.Get(C);
        Observer.ObserveError('char missing');
        Observer.Expect('guid missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('guid missing|code', 'KeyNotFound');
        Observer.Expect('guid duplicate|text', 'An item with the same key has already been added.');
        Observer.Expect('guid duplicate|code', 'Argument');
        Observer.Expect('time missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('time missing|code', 'KeyNotFound');
        Observer.Expect('datetime missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('datetime missing|code', 'KeyNotFound');
        Observer.Expect('char missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('char missing|code', 'KeyNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Err_ValueTypesMissingKey()
    var
        Observer: Codeunit "Probe Observer";
        DL: Dictionary of [Text, List of [Integer]];
        DD: Dictionary of [Text, Dictionary of [Text, Integer]];
        DI: Dictionary of [Text, Interface "LT ClT Shape"];
        L: List of [Integer];
        D: Dictionary of [Text, Integer];
        I: Interface "LT ClT Shape";
    begin
        asserterror L := DL.Get('x');
        Observer.ObserveError('list value missing');
        asserterror D := DD.Get('x');
        Observer.ObserveError('dict value missing');
        asserterror I := DI.Get('x');
        Observer.ObserveError('interface value missing');
        Observer.Observe('out form list ret', Format(DL.Get('x', L)));
        Observer.Observe('out form dict ret', Format(DD.Get('x', D)));
        Observer.Expect('list value missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('list value missing|code', 'KeyNotFound');
        Observer.Expect('dict value missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('dict value missing|code', 'KeyNotFound');
        Observer.Expect('interface value missing|text', 'The given key was not present in the dictionary.');
        Observer.Expect('interface value missing|code', 'KeyNotFound');
        Observer.Expect('out form list ret', 'No');
        Observer.Expect('out form dict ret', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Err_SetAndRemoveNoError()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Set('new', 1);
        Observer.Observe('set on missing creates', Format(D.Get('new')));
        Observer.Observe('remove missing', Format(D.Remove('nothing')));
        Observer.Observe('remove existing', Format(D.Remove('new')));
        Observer.Observe('count', Format(D.Count()));
        Observer.Expect('set on missing creates', '1');
        Observer.Expect('remove missing', 'No');
        Observer.Expect('remove existing', 'Yes');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;
}
