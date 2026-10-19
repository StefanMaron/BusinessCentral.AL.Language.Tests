// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74622
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Dictionary key equality per key type: Text and Code case sensitivity, trailing spaces, Decimal scale, Date/Time/DateTime, Guid, Char, Enum, Boolean, BigInteger.
// BC versions: 29 (27 and 28 by CI)

codeunit 74622 "LT ClT Dict Keys"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Text_CaseSensitivity()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Add('Apple', 1);
        Observer.Observe('contains apple', Format(D.ContainsKey('apple')));
        Observer.Observe('contains APPLE', Format(D.ContainsKey('APPLE')));
        Observer.Observe('contains Apple', Format(D.ContainsKey('Apple')));
        D.Add('apple', 2);
        D.Add('APPLE', 3);
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('get apple', Format(D.Get('apple')));
        Observer.Observe('get APPLE', Format(D.Get('APPLE')));
        Observer.Observe('remove aPPLE', Format(D.Remove('aPPLE')));
        Observer.Observe('remove APPLE', Format(D.Remove('APPLE')));
        Observer.Observe('count after', Format(D.Count()));
        Observer.Expect('contains apple', 'No');
        Observer.Expect('contains APPLE', 'No');
        Observer.Expect('contains Apple', 'Yes');
        Observer.Expect('count', '3');
        Observer.Expect('get apple', '2');
        Observer.Expect('get APPLE', '3');
        Observer.Expect('remove aPPLE', 'No');
        Observer.Expect('remove APPLE', 'Yes');
        Observer.Expect('count after', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Whitespace()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Add('a', 1);
        D.Add('a ', 2);
        D.Add(' a', 3);
        D.Add('', 4);
        D.Add(' ', 5);
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('get a', Format(D.Get('a')));
        Observer.Observe('get a+space', Format(D.Get('a ')));
        Observer.Observe('get space+a', Format(D.Get(' a')));
        Observer.Observe('get empty', Format(D.Get('')));
        Observer.Observe('get space', Format(D.Get(' ')));
        Observer.Observe('contains two spaces', Format(D.ContainsKey('  ')));
        Observer.Observe('contains a+two spaces', Format(D.ContainsKey('a  ')));
        Observer.Expect('count', '5');
        Observer.Expect('get a', '1');
        Observer.Expect('get a+space', '2');
        Observer.Expect('get space+a', '3');
        Observer.Expect('get empty', '4');
        Observer.Expect('get space', '5');
        Observer.Expect('contains two spaces', 'No');
        Observer.Expect('contains a+two spaces', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Unicode()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Add('é', 1);
        D.Add('ÄÖÜ', 2);
        D.Add('straße', 3);
        Observer.Observe('contains É', Format(D.ContainsKey('É')));
        Observer.Observe('contains äöü', Format(D.ContainsKey('äöü')));
        Observer.Observe('contains STRASSE', Format(D.ContainsKey('STRASSE')));
        Observer.Observe('contains strasse', Format(D.ContainsKey('strasse')));
        Observer.Observe('contains e', Format(D.ContainsKey('e')));
        Observer.Observe('contains ß upper', Format(D.ContainsKey('STRAßE')));
        Observer.Expect('contains É', 'No');
        Observer.Expect('contains äöü', 'No');
        Observer.Expect('contains STRASSE', 'No');
        Observer.Expect('contains strasse', 'No');
        Observer.Expect('contains e', 'No');
        Observer.Expect('contains ß upper', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Code_CaseSensitivity()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Code[20], Integer];
        K: Code[20];
    begin
        D.Add('abc', 1);
        Observer.Observe('contains ABC', Format(D.ContainsKey('ABC')));
        Observer.Observe('contains abc', Format(D.ContainsKey('abc')));
        Observer.Observe('contains aBc', Format(D.ContainsKey('aBc')));
        Observer.Observe('contains abc+space', Format(D.ContainsKey('abc ')));
        Observer.Observe('keys 1', D.Keys().Get(1));
        K := 'xyz';
        D.Add(K, 2);
        Observer.Observe('contains XYZ', Format(D.ContainsKey('XYZ')));
        Observer.Observe('count', Format(D.Count()));
        Observer.Expect('contains ABC', 'Yes');
        Observer.Expect('contains abc', 'Yes');
        Observer.Expect('contains aBc', 'Yes');
        Observer.Expect('contains abc+space', 'Yes');
        Observer.Expect('keys 1', 'ABC');
        Observer.Expect('contains XYZ', 'Yes');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Text_VsCodeTyped()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text[10], Integer];
    begin
        asserterror D.Add('abcdefghijklmnop', 1);
        Observer.ObserveError('af100');
        asserterror Observer.Observe('key truncated', D.Keys().Get(1));
        Observer.ObserveError('af102');
        asserterror Observer.Observe('contains full', Format(D.ContainsKey('abcdefghijklmnop')));
        Observer.ObserveError('af104');
        Observer.Observe('contains truncated', Format(D.ContainsKey('abcdefghij')));
        Observer.Expect('af100|text', 'The length of the string is 16, but it must be less than or equal to 10 characters. Value: abcdefghijklmnop');
        Observer.Expect('af100|code', 'StringLengthExceeded');
        Observer.Expect('af102|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('af102|code', 'ArgumentOutOfRange');
        Observer.Expect('af104|text', 'The length of the string is 16, but it must be less than or equal to 10 characters. Value: abcdefghijklmnop');
        Observer.Expect('af104|code', 'StringLengthExceeded');
        Observer.Expect('contains truncated', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Keys()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Integer, Text];
    begin
        D.Add(0, 'zero');
        D.Add(-1, 'neg');
        D.Add(2147483647, 'max');
        D.Add(-2147483647, 'min+1');
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('get 0', D.Get(0));
        Observer.Observe('get -1', D.Get(-1));
        Observer.Observe('get max', D.Get(2147483647));
        Observer.Observe('contains 1', Format(D.ContainsKey(1)));
        Observer.Observe('keys 3', Format(D.Keys().Get(3)));
        Observer.Expect('count', '4');
        Observer.Expect('get 0', 'zero');
        Observer.Expect('get -1', 'neg');
        Observer.Expect('get max', 'max');
        Observer.Expect('contains 1', 'No');
        Observer.Expect('keys 3', '2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Keys()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Decimal, Text];
    begin
        D.Add(1.5, 'a');
        D.Add(2, 'b');
        D.Add(0, 'z');
        Observer.Observe('contains 1.50', Format(D.ContainsKey(1.50)));
        Observer.Observe('contains 2.0', Format(D.ContainsKey(2.0)));
        Observer.Observe('contains 1.500000001', Format(D.ContainsKey(1.5000000001)));
        Observer.Observe('contains -0', Format(D.ContainsKey(-0)));
        Observer.Observe('contains 1/3 expr', Format(D.ContainsKey(1 / 3)));
        D.Add(1 / 3, 'third');
        Observer.Observe('contains 0.333333333333333333', Format(D.ContainsKey(0.333333333333333333)));
        Observer.Observe('contains 0.333333', Format(D.ContainsKey(0.333333)));
        Observer.Observe('get 2', D.Get(2));
        Observer.Expect('contains 1.50', 'Yes');
        Observer.Expect('contains 2.0', 'Yes');
        Observer.Expect('contains 1.500000001', 'No');
        Observer.Expect('contains -0', 'Yes');
        Observer.Expect('contains 1/3 expr', 'No');
        Observer.Expect('contains 0.333333333333333333', 'Yes');
        Observer.Expect('contains 0.333333', 'No');
        Observer.Expect('get 2', 'b');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_Keys()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Boolean, Text];
    begin
        D.Add(true, 't');
        D.Add(false, 'f');
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('get true', D.Get(true));
        Observer.Observe('get false', D.Get(false));
        Observer.Observe('keys 1', Format(D.Keys().Get(1)));
        Observer.Expect('count', '2');
        Observer.Expect('get true', 't');
        Observer.Expect('get false', 'f');
        Observer.Expect('keys 1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Keys()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Date, Text];
        Blank: Date;
    begin
        D.Add(DMY2Date(1, 2, 2020), 'a');
        D.Add(0D, 'blank');
        D.Add(DMY2Date(31, 12, 9999), 'max');
        Observer.Observe('contains 2020-02-01', Format(D.ContainsKey(DMY2Date(1, 2, 2020))));
        Observer.Observe('contains blank var', Format(D.ContainsKey(Blank)));
        Observer.Observe('contains max', Format(D.ContainsKey(DMY2Date(31, 12, 9999))));
        Observer.Observe('contains next day', Format(D.ContainsKey(DMY2Date(2, 2, 2020))));
        Observer.Observe('get blank', D.Get(0D));
        Observer.Observe('key 2', Format(D.Keys().Get(2), 0, 9));
        Observer.Expect('contains 2020-02-01', 'Yes');
        Observer.Expect('contains blank var', 'Yes');
        Observer.Expect('contains max', 'Yes');
        Observer.Expect('contains next day', 'No');
        Observer.Expect('get blank', 'blank');
        Observer.Expect('key 2', '');
        Observer.Verify();
    end;

    [Test]
    procedure Time_DateTime_Keys()
    var
        Observer: Codeunit "Probe Observer";
        DT: Dictionary of [Time, Text];
        DDT: Dictionary of [DateTime, Text];
    begin
        DT.Add(120000T, 'noon');
        DT.Add(0T, 'blank');
        DT.Add(235959.999T, 'last');
        Observer.Observe('time contains noon', Format(DT.ContainsKey(120000T)));
        Observer.Observe('time contains blank', Format(DT.ContainsKey(0T)));
        Observer.Observe('time contains 235959.998', Format(DT.ContainsKey(235959.998T)));
        DDT.Add(CreateDateTime(DMY2Date(1, 1, 2020), 100000T), 'a');
        DDT.Add(0DT, 'blank');
        Observer.Observe('datetime contains same', Format(DDT.ContainsKey(CreateDateTime(DMY2Date(1, 1, 2020), 100000T))));
        Observer.Observe('datetime contains +1ms', Format(DDT.ContainsKey(CreateDateTime(DMY2Date(1, 1, 2020), 100000.001T))));
        Observer.Observe('datetime contains blank', Format(DDT.ContainsKey(0DT)));
        Observer.Observe('datetime count', Format(DDT.Count()));
        Observer.Expect('time contains noon', 'Yes');
        Observer.Expect('time contains blank', 'Yes');
        Observer.Expect('time contains 235959.998', 'No');
        Observer.Expect('datetime contains same', 'Yes');
        Observer.Expect('datetime contains +1ms', 'No');
        Observer.Expect('datetime contains blank', 'Yes');
        Observer.Expect('datetime count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Char_Guid_Keys()
    var
        Observer: Codeunit "Probe Observer";
        DC: Dictionary of [Char, Integer];
        DG: Dictionary of [Guid, Integer];
        C: Char;
        G: Guid;
        G2: Guid;
        Blank: Guid;
    begin
        C := 'a';
        DC.Add(C, 1);
        C := 'A';
        DC.Add(C, 2);
        C := 'a';
        Observer.Observe('char a', Format(DC.Get(C)));
        C := 'A';
        Observer.Observe('char A', Format(DC.Get(C)));
        Observer.Observe('char count', Format(DC.Count()));
        Evaluate(G, '{11111111-2222-3333-4444-555555555555}');
        DG.Add(G, 1);
        DG.Add(Blank, 2);
        Evaluate(G2, '{11111111-2222-3333-4444-555555555555}');
        Observer.Observe('guid same value other var', Format(DG.Get(G2)));
        Observer.Observe('guid blank', Format(DG.Get(Blank)));
        Evaluate(G2, '{11111111-2222-3333-4444-555555555556}');
        Observer.Observe('guid different', Format(DG.ContainsKey(G2)));
        Observer.Expect('char a', '1');
        Observer.Expect('char A', '2');
        Observer.Expect('char count', '2');
        Observer.Expect('guid same value other var', '1');
        Observer.Expect('guid blank', '2');
        Observer.Expect('guid different', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Enum_BigInteger_Keys()
    var
        Observer: Codeunit "Probe Observer";
        DE: Dictionary of [Enum "LT ClT Color", Integer];
        DB: Dictionary of [BigInteger, Integer];
        C: Enum "LT ClT Color";
        B: BigInteger;
    begin
        DE.Add(Enum::"LT ClT Color"::Red, 1);
        DE.Add(Enum::"LT ClT Color"::Blue, 5);
        Observer.Observe('count', Format(DE.Count()));
        C := Enum::"LT ClT Color".FromInteger(5);
        Observer.Observe('get FromInteger(5)', Format(DE.Get(C)));
        Observer.Observe('contains Green', Format(DE.ContainsKey(Enum::"LT ClT Color"::Green)));
        Observer.Observe('keys 2 format', Format(DE.Keys().Get(2)));
        Observer.Observe('keys 2 ordinal', Format(DE.Keys().Get(2).AsInteger()));
        B := 3000000;
        B := B * 1000;
        DB.Add(B, 1);
        DB.Add(1, 2);
        Observer.Observe('big get', Format(DB.Get(B)));
        Observer.Observe('big contains int 1', Format(DB.ContainsKey(1)));
        Observer.Observe('big contains 1000', Format(DB.ContainsKey(1000)));
        Observer.Expect('count', '2');
        Observer.Expect('get FromInteger(5)', '5');
        Observer.Expect('contains Green', 'No');
        Observer.Expect('keys 2 format', 'Blue Caption');
        Observer.Expect('keys 2 ordinal', '5');
        Observer.Expect('big get', '1');
        Observer.Expect('big contains int 1', 'Yes');
        Observer.Expect('big contains 1000', 'No');
        Observer.Verify();
    end;
}
