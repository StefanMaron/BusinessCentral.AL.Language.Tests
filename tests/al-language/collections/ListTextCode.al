// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74614
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List of [Text] and [Code]: case sensitivity of Contains/IndexOf/LastIndexOf/Remove, blanks, trailing spaces, unicode, length truncation.
// BC versions: 29 (27 and 28 by CI)

codeunit 74614 "LT ClT List Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Text_CaseBehaviour()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
    begin
        L.Add('Apple');
        L.Add('apple');
        L.Add('APPLE');
        L.Add('');
        L.Add(' ');
        L.Add('apple ');
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('indexof apple', Format(L.IndexOf('apple')));
        Observer.Observe('indexof Apple', Format(L.IndexOf('Apple')));
        Observer.Observe('indexof aPPLE', Format(L.IndexOf('aPPLE')));
        Observer.Observe('contains aPPLE', Format(L.Contains('aPPLE')));
        Observer.Observe('lastindexof apple', Format(L.LastIndexOf('apple')));
        Observer.Observe('indexof empty', Format(L.IndexOf('')));
        Observer.Observe('indexof single space', Format(L.IndexOf(' ')));
        Observer.Observe('indexof two spaces', Format(L.IndexOf('  ')));
        Observer.Observe('indexof apple+space', Format(L.IndexOf('apple ')));
        Observer.Observe('indexof apple+2 spaces', Format(L.IndexOf('apple  ')));
        Observer.Expect('count', '6');
        Observer.Expect('indexof apple', '2');
        Observer.Expect('indexof Apple', '1');
        Observer.Expect('indexof aPPLE', '0');
        Observer.Expect('contains aPPLE', 'No');
        Observer.Expect('lastindexof apple', '2');
        Observer.Expect('indexof empty', '4');
        Observer.Expect('indexof single space', '5');
        Observer.Expect('indexof two spaces', '0');
        Observer.Expect('indexof apple+space', '6');
        Observer.Expect('indexof apple+2 spaces', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Text_RemoveCase()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
    begin
        L.Add('Apple');
        L.Add('apple');
        Observer.Observe('remove APPLE', Format(L.Remove('APPLE')));
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('remove apple', Format(L.Remove('apple')));
        Observer.Observe('left', L.Get(1));
        Observer.Expect('remove APPLE', 'No');
        Observer.Expect('count', '2');
        Observer.Expect('remove apple', 'Yes');
        Observer.Expect('left', 'Apple');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Unicode()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        Lo: Text;
        Up: Text;
    begin
        Lo := 'straße';
        Up := 'STRASSE';
        L.Add(Lo);
        L.Add('ÄÖÜ');
        L.Add('é');
        L.Add('e');
        Observer.Observe('indexof ä', Format(L.IndexOf('äöü')));
        Observer.Observe('indexof É', Format(L.IndexOf('É')));
        Observer.Observe('indexof e', Format(L.IndexOf('e')));
        Observer.Observe('indexof STRASSE', Format(L.IndexOf(Up)));
        Observer.Observe('indexof ÄÖÜ', Format(L.IndexOf('ÄÖÜ')));
        Observer.Expect('indexof ä', '0');
        Observer.Expect('indexof É', '0');
        Observer.Expect('indexof e', '4');
        Observer.Expect('indexof STRASSE', '0');
        Observer.Expect('indexof ÄÖÜ', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Text_LongValues()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        Long: Text;
    begin
        Long := PadStr('', 5000, 'x');
        L.Add(Long);
        L.Add(Long + 'y');
        Observer.Observe('len 1', Format(StrLen(L.Get(1))));
        Observer.Observe('len 2', Format(StrLen(L.Get(2))));
        Observer.Observe('indexof long', Format(L.IndexOf(Long)));
        Observer.Observe('indexof long+y', Format(L.IndexOf(Long + 'y')));
        Observer.Observe('contains short', Format(L.Contains('x')));
        Observer.Expect('len 1', '5000');
        Observer.Expect('len 2', '5001');
        Observer.Expect('indexof long', '1');
        Observer.Expect('indexof long+y', '2');
        Observer.Expect('contains short', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Code_CaseBehaviour()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Code[20]];
        C: Code[20];
    begin
        L.Add('abc');
        L.Add('ABD');
        L.Add('');
        Observer.Observe('get 1 (upper cased on add?)', L.Get(1));
        Observer.Observe('indexof ABC', Format(L.IndexOf('ABC')));
        Observer.Observe('indexof abc', Format(L.IndexOf('abc')));
        Observer.Observe('indexof aBd', Format(L.IndexOf('aBd')));
        C := 'abd';
        Observer.Observe('contains var abd', Format(L.Contains(C)));
        Observer.Observe('indexof empty', Format(L.IndexOf('')));
        Observer.Observe('indexof abc+space', Format(L.IndexOf('abc ')));
        Observer.Expect('get 1 (upper cased on add?)', 'ABC');
        Observer.Expect('indexof ABC', '1');
        Observer.Expect('indexof abc', '1');
        Observer.Expect('indexof aBd', '2');
        Observer.Expect('contains var abd', 'Yes');
        Observer.Expect('indexof empty', '3');
        Observer.Expect('indexof abc+space', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CodeUnbounded_List()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Code[10]];
        T: List of [Text[10]];
    begin
        L.Add('x');
        Observer.Observe('code10 get', L.Get(1));
        T.Add('Hello');
        Observer.Observe('text10 contains hello', Format(T.Contains('hello')));
        Observer.Observe('text10 contains Hello', Format(T.Contains('Hello')));
        Observer.Expect('code10 get', 'X');
        Observer.Expect('text10 contains hello', 'No');
        Observer.Expect('text10 contains Hello', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Text_SetInsertKeepsValues()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
    begin
        L.Add('a');
        L.Set(1, 'B');
        Observer.Observe('after set', L.Get(1));
        L.Insert(1, 'c');
        Observer.Observe('insert', L.Get(1) + L.Get(2));
        Observer.Observe('contains b', Format(L.Contains('b')));
        Observer.Expect('after set', 'B');
        Observer.Expect('insert', 'cB');
        Observer.Expect('contains b', 'No');
        Observer.Verify();
    end;
}
