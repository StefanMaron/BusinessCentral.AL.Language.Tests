// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type
// Scope: in-scope
// Fixtures used: Fixtures.al (interface LT ClT Shape, codeunits 74600/74601, enum 74602), codeunit 74623
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Dictionary value types: Decimal, Boolean, Date, Enum, Text, Code, interface, List, Dictionary, TextBuilder; values are stored by copy or reference; Keys/Values of nested collections.
// BC versions: 29 (27 and 28 by CI)

codeunit 74623 "LT ClT Dict Values"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Values_Scalars()
    var
        Observer: Codeunit "Probe Observer";
        DD: Dictionary of [Integer, Decimal];
        DB: Dictionary of [Integer, Boolean];
        DDt: Dictionary of [Integer, Date];
        DTm: Dictionary of [Integer, Time];
        DDtm: Dictionary of [Integer, DateTime];
        DE: Dictionary of [Integer, Enum "LT ClT Color"];
        DC: Dictionary of [Integer, Code[5]];
    begin
        DD.Add(1, 1.50);
        DD.Add(2, 1 / 3);
        Observer.Observe('decimal 1', Format(DD.Get(1)));
        Observer.Observe('decimal 2', Format(DD.Get(2), 0, 9));
        DB.Add(1, true);
        Observer.Observe('bool', Format(DB.Get(1)));
        DDt.Add(1, DMY2Date(5, 6, 2021));
        DDt.Add(2, 0D);
        Observer.Observe('date', Format(DDt.Get(1), 0, 9));
        Observer.Observe('blank date', Format(DDt.Get(2), 0, 9));
        DTm.Add(1, 130500T);
        Observer.Observe('time', Format(DTm.Get(1), 0, 9));
        DDtm.Add(1, 0DT);
        Observer.Observe('datetime blank', Format(DDtm.Get(1), 0, 9));
        DE.Add(1, Enum::"LT ClT Color"::Blue);
        Observer.Observe('enum', Format(DE.Get(1)));
        Observer.Observe('enum ordinal', Format(DE.Get(1).AsInteger()));
        asserterror DC.Add(1, 'abcdefgh');
        Observer.ObserveError('af42');
        asserterror Observer.Observe('code[5] long', DC.Get(1));
        Observer.ObserveError('af44');
        DC.Add(2, 'ab');
        Observer.Observe('code lowercase', DC.Get(2));
        Observer.Expect('decimal 1', '1.5');
        Observer.Expect('decimal 2', '0.333333333333333333');
        Observer.Expect('bool', 'Yes');
        Observer.Expect('date', '2021-06-05');
        Observer.Expect('blank date', '');
        Observer.Expect('time', '13:05:00');
        Observer.Expect('datetime blank', '');
        Observer.Expect('enum', 'Blue Caption');
        Observer.Expect('enum ordinal', '5');
        Observer.Expect('af42|text', 'The length of the string is 8, but it must be less than or equal to 5 characters. Value: abcdefgh');
        Observer.Expect('af42|code', 'StringLengthExceeded');
        Observer.Expect('af44|text', 'The given key was not present in the dictionary.');
        Observer.Expect('af44|code', 'KeyNotFound');
        Observer.Expect('code lowercase', 'AB');
        Observer.Verify();
    end;

    [Test]
    procedure Values_TextLong()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Text];
        DT: Dictionary of [Text, Text[3]];
        Long: Text;
    begin
        Long := PadStr('', 3000, 'q');
        D.Add('k', Long);
        Observer.Observe('len', Format(StrLen(D.Get('k'))));
        asserterror DT.Add('k', 'abcdef');
        Observer.ObserveError('af61');
        asserterror Observer.Observe('text[3] value', DT.Get('k'));
        Observer.ObserveError('af64');
        D.Set('k', '');
        Observer.Observe('empty value', Format(StrLen(D.Get('k'))));
        Observer.Observe('contains empty value', Format(D.Values().Contains('')));
        Observer.Expect('len', '3000');
        Observer.Expect('af61|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('af61|code', 'StringLengthExceeded');
        Observer.Expect('af64|text', 'The given key was not present in the dictionary.');
        Observer.Expect('af64|code', 'KeyNotFound');
        Observer.Expect('empty value', '0');
        Observer.Expect('contains empty value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Values_ListOfInteger()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, List of [Integer]];
        L: List of [Integer];
        Got: List of [Integer];
    begin
        L.Add(1);
        D.Add('a', L);
        L.Add(2);
        D.Get('a', Got);
        Observer.Observe('got count after source add', Format(Got.Count()));
        Got.Add(3);
        Observer.Observe('dict elem count after got add', Format(D.Get('a').Count()));
        Observer.Observe('source count', Format(L.Count()));
        D.Add('b', L);
        L.Add(4);
        Observer.Observe('b count', Format(D.Get('b').Count()));
        Observer.Observe('a count', Format(D.Get('a').Count()));
        Observer.Observe('same list shared a/b', Format(D.Get('a').Count() = D.Get('b').Count()));
        Observer.Expect('got count after source add', '2');
        Observer.Expect('dict elem count after got add', '3');
        Observer.Expect('source count', '3');
        Observer.Expect('b count', '4');
        Observer.Expect('a count', '4');
        Observer.Expect('same list shared a/b', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Values_DictOfDict()
    var
        Observer: Codeunit "Probe Observer";
        Outer: Dictionary of [Text, Dictionary of [Text, Integer]];
        Inner: Dictionary of [Text, Integer];
        Got: Dictionary of [Text, Integer];
    begin
        Inner.Add('x', 1);
        Outer.Add('o', Inner);
        Inner.Add('y', 2);
        Outer.Get('o', Got);
        Observer.Observe('got count', Format(Got.Count()));
        Got.Add('z', 3);
        Observer.Observe('outer elem count', Format(Outer.Get('o').Count()));
        Observer.Observe('inner count', Format(Inner.Count()));
        Observer.Observe('deep get', Format(Outer.Get('o').Get('x')));
        Observer.Observe('values count', Format(Outer.Values().Count()));
        Observer.Expect('got count', '2');
        Observer.Expect('outer elem count', '3');
        Observer.Expect('inner count', '3');
        Observer.Expect('deep get', '1');
        Observer.Expect('values count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Values_Interface()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Interface "LT ClT Shape"];
        C: Codeunit "LT ClT Circle";
        S: Codeunit "LT ClT Square";
        I: Interface "LT ClT Shape";
    begin
        C.SetTag('1');
        I := C;
        D.Add('c', I);
        I := S;
        D.Add('s', I);
        Observer.Observe('c', D.Get('c').Name());
        Observer.Observe('s', D.Get('s').Name());
        C.SetTag('2');
        Observer.Observe('c after retag', D.Get('c').Name());
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('values count', Format(D.Values().Count()));
        Observer.Observe('values 1', D.Values().Get(1).Name());
        Observer.Observe('keys', D.Keys().Get(1) + D.Keys().Get(2));
        Observer.Expect('c', 'circle1');
        Observer.Expect('s', 'square');
        Observer.Expect('c after retag', 'circle2');
        Observer.Expect('count', '2');
        Observer.Expect('values count', '2');
        Observer.Expect('values 1', 'circle2');
        Observer.Expect('keys', 'cs');
        Observer.Verify();
    end;

    [Test]
    procedure Values_ListKeysOfDictionary()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        K: List of [Text];
        V: List of [Integer];
        i: Integer;
    begin
        for i := 1 to 5 do
            D.Add('k' + Format(i), i * i);
        K := D.Keys();
        V := D.Values();
        Observer.Observe('keys count', Format(K.Count()));
        Observer.Observe('values 3', Format(V.Get(3)));
        Observer.Observe('keys indexof k4', Format(K.IndexOf('k4')));
        Observer.Observe('keys contains K4', Format(K.Contains('K4')));
        Observer.Observe('keys remove from snapshot', Format(K.Remove('k1')));
        Observer.Observe('dict still has k1', Format(D.ContainsKey('k1')));
        Observer.Observe('values range', Format(V.GetRange(2, 2).Count()));
        Observer.Expect('keys count', '5');
        Observer.Expect('values 3', '9');
        Observer.Expect('keys indexof k4', '4');
        Observer.Expect('keys contains K4', 'No');
        Observer.Expect('keys remove from snapshot', 'Yes');
        Observer.Expect('dict still has k1', 'Yes');
        Observer.Expect('values range', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Values_Large()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Integer, Integer];
        L: List of [Integer];
        i: Integer;
        Sum: Integer;
        X: Integer;
    begin
        for i := 1 to 2000 do begin
            D.Add(i, i * 2);
            L.Add(i);
        end;
        Observer.Observe('dict count', Format(D.Count()));
        Observer.Observe('list count', Format(L.Count()));
        foreach X in D.Values() do
            Sum += X;
        Observer.Observe('sum', Format(Sum));
        Observer.Observe('get 1500', Format(D.Get(1500)));
        Observer.Observe('indexof 2000', Format(L.IndexOf(2000)));
        for i := 1 to 1000 do
            D.Remove(i);
        Observer.Observe('count after remove', Format(D.Count()));
        Observer.Observe('first key', Format(D.Keys().Get(1)));
        Observer.Expect('dict count', '2000');
        Observer.Expect('list count', '2000');
        Observer.Expect('sum', '4002000');
        Observer.Expect('get 1500', '3000');
        Observer.Expect('indexof 2000', '2000');
        Observer.Expect('count after remove', '1000');
        Observer.Expect('first key', '1001');
        Observer.Verify();
    end;

    // Corpus issue #664 item 110: Dictionary of [Integer, TextBuilder] compiles and works; is the stored builder a copy or the same builder?
    [Test]
    procedure Values_TextBuilder()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Integer, TextBuilder];
        TB: TextBuilder;
        TB2: TextBuilder;
        Got: TextBuilder;
    begin
        TB.Append('x');
        D.Add(1, TB);
        Observer.Observe('stored', D.Get(1).ToText());
        TB.Append('y');
        Observer.Observe('after appending to the added variable', D.Get(1).ToText());
        Got := D.Get(1);
        Got.Append('z');
        Observer.Observe('after appending to a Get result', D.Get(1).ToText());
        D.Get(1, TB2);
        TB2.Append('w');
        Observer.Observe('after appending to a Get var result', D.Get(1).ToText());
        D.Set(1, TB);
        Observer.Observe('after set', D.Get(1).ToText());
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('length', Format(D.Get(1).Length()));
        Observer.Finish();
    end;
}
