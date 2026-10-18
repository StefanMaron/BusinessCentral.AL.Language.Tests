// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 69371
// Facts: the 20 text methods (Contains, EndsWith, IndexOf, IndexOfAny with a list of Char and with a Text, LastIndexOf, PadLeft, PadRight, Remove, Replace, Split with Text, with a list of Char and with a list of Text,
// StartsWith, Substring, ToLower, ToUpper, Trim, TrimEnd, TrimStart) called on a TextConst variable and, for each case, on a Text variable that holds the same text. Every case is observed twice, as "tc <case>" and
// "text <case>", and the two values are the same; the error cases pin the error text.
// BC versions: 27.0 and later

codeunit 69371 "LT T TextConst Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        TcHello: TextConst ENU = 'Hello World Hello';
        TcSep: TextConst ENU = 'a,b;c d,,e';
        TcMixed: TextConst ENU = 'MiXed Case 123 ÄÖ';
        TcPad: TextConst ENU = '  padded  ';
        TcChars: TextConst ENU = 'xxabcxx';

    local procedure Join(Parts: List of [Text]): Text
    var
        Part: Text;
        Result: Text;
    begin
        foreach Part in Parts do
            Result += '|' + Part;
        exit(Format(Parts.Count()) + Result);
    end;

    [Test]
    procedure TextConst_Contains()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc true', Format(TcHello.Contains('World')));
        Observer.Observe('text true', Format(T.Contains('World')));
        Observer.Observe('tc false', Format(TcHello.Contains('xyz')));
        Observer.Observe('text false', Format(T.Contains('xyz')));
        Observer.Observe('tc different case', Format(TcHello.Contains('world')));
        Observer.Observe('text different case', Format(T.Contains('world')));
        Observer.Observe('tc empty value', Format(TcHello.Contains('')));
        Observer.Observe('text empty value', Format(T.Contains('')));
        Observer.Observe('tc whole text', Format(TcHello.Contains('Hello World Hello')));
        Observer.Observe('text whole text', Format(T.Contains('Hello World Hello')));
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_EndsWith()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc true', Format(TcHello.EndsWith('Hello')));
        Observer.Observe('text true', Format(T.EndsWith('Hello')));
        Observer.Observe('tc false', Format(TcHello.EndsWith('World')));
        Observer.Observe('text false', Format(T.EndsWith('World')));
        Observer.Observe('tc different case', Format(TcHello.EndsWith('hello')));
        Observer.Observe('text different case', Format(T.EndsWith('hello')));
        Observer.Observe('tc empty value', Format(TcHello.EndsWith('')));
        Observer.Observe('text empty value', Format(T.EndsWith('')));
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_IndexOf()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.IndexOf('o')));
        Observer.Observe('text found', Format(T.IndexOf('o')));
        Observer.Observe('tc found from 6', Format(TcHello.IndexOf('o', 6)));
        Observer.Observe('text found from 6', Format(T.IndexOf('o', 6)));
        Observer.Observe('tc found text from 2', Format(TcHello.IndexOf('Hello', 2)));
        Observer.Observe('text found text from 2', Format(T.IndexOf('Hello', 2)));
        Observer.Observe('tc missing', Format(TcHello.IndexOf('zzz')));
        Observer.Observe('text missing', Format(T.IndexOf('zzz')));
        Observer.Observe('tc missing from 3', Format(TcHello.IndexOf('zzz', 3)));
        Observer.Observe('text missing from 3', Format(T.IndexOf('zzz', 3)));
        Observer.Observe('tc different case', Format(TcHello.IndexOf('world')));
        Observer.Observe('text different case', Format(T.IndexOf('world')));
        Observer.Observe('tc empty value', Format(TcHello.IndexOf('')));
        Observer.Observe('text empty value', Format(T.IndexOf('')));
        asserterror I := TcHello.IndexOf('o', 0);
        Observer.ObserveError('tc start 0');
        asserterror I := T.IndexOf('o', 0);
        Observer.ObserveError('text start 0');
        asserterror I := TcHello.IndexOf('o', 100);
        Observer.ObserveError('tc start past end');
        asserterror I := T.IndexOf('o', 100);
        Observer.ObserveError('text start past end');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_IndexOfAnyChars()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        C.Add('W'); C.Add('o');
        D.Add('z'); D.Add('q');
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.IndexOfAny(C)));
        Observer.Observe('text found', Format(T.IndexOfAny(C)));
        Observer.Observe('tc found from 6', Format(TcHello.IndexOfAny(C, 6)));
        Observer.Observe('text found from 6', Format(T.IndexOfAny(C, 6)));
        Observer.Observe('tc missing', Format(TcHello.IndexOfAny(D)));
        Observer.Observe('text missing', Format(T.IndexOfAny(D)));
        Observer.Observe('tc missing from 3', Format(TcHello.IndexOfAny(D, 3)));
        Observer.Observe('text missing from 3', Format(T.IndexOfAny(D, 3)));
        asserterror I := TcHello.IndexOfAny(C, 0);
        Observer.ObserveError('tc start 0');
        asserterror I := T.IndexOfAny(C, 0);
        Observer.ObserveError('text start 0');
        asserterror I := TcHello.IndexOfAny(C, 100);
        Observer.ObserveError('tc start past end');
        asserterror I := T.IndexOfAny(C, 100);
        Observer.ObserveError('text start past end');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_IndexOfAnyText()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.IndexOfAny('Wo')));
        Observer.Observe('text found', Format(T.IndexOfAny('Wo')));
        Observer.Observe('tc found from 6', Format(TcHello.IndexOfAny('Wo', 6)));
        Observer.Observe('text found from 6', Format(T.IndexOfAny('Wo', 6)));
        Observer.Observe('tc missing', Format(TcHello.IndexOfAny('zq')));
        Observer.Observe('text missing', Format(T.IndexOfAny('zq')));
        Observer.Observe('tc missing from 3', Format(TcHello.IndexOfAny('zq', 3)));
        Observer.Observe('text missing from 3', Format(T.IndexOfAny('zq', 3)));
        asserterror I := TcHello.IndexOfAny('Wo', 0);
        Observer.ObserveError('tc start 0');
        asserterror I := T.IndexOfAny('Wo', 0);
        Observer.ObserveError('text start 0');
        asserterror I := TcHello.IndexOfAny('Wo', 100);
        Observer.ObserveError('tc start past end');
        asserterror I := T.IndexOfAny('Wo', 100);
        Observer.ObserveError('text start past end');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_LastIndexOf()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc found', Format(TcHello.LastIndexOf('o')));
        Observer.Observe('text found', Format(T.LastIndexOf('o')));
        Observer.Observe('tc found with start 17', Format(TcHello.LastIndexOf('o', 17)));
        Observer.Observe('text found with start 17', Format(T.LastIndexOf('o', 17)));
        Observer.Observe('tc found with start 10', Format(TcHello.LastIndexOf('o', 10)));
        Observer.Observe('text found with start 10', Format(T.LastIndexOf('o', 10)));
        Observer.Observe('tc found text', Format(TcHello.LastIndexOf('Hello')));
        Observer.Observe('text found text', Format(T.LastIndexOf('Hello')));
        Observer.Observe('tc missing', Format(TcHello.LastIndexOf('zzz')));
        Observer.Observe('text missing', Format(T.LastIndexOf('zzz')));
        Observer.Observe('tc missing with start 5', Format(TcHello.LastIndexOf('zzz', 5)));
        Observer.Observe('text missing with start 5', Format(T.LastIndexOf('zzz', 5)));
        asserterror I := TcHello.LastIndexOf('o', 0);
        Observer.ObserveError('tc start 0');
        asserterror I := T.LastIndexOf('o', 0);
        Observer.ObserveError('text start 0');
        asserterror I := TcHello.LastIndexOf('o', 100);
        Observer.ObserveError('tc start past end');
        asserterror I := T.LastIndexOf('o', 100);
        Observer.ObserveError('text start past end');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_PadLeft()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc default char', TcHello.PadLeft(20));
        Observer.Observe('text default char', T.PadLeft(20));
        Observer.Observe('tc given char', TcHello.PadLeft(20, '*'));
        Observer.Observe('text given char', T.PadLeft(20, '*'));
        Observer.Observe('tc shorter count', TcHello.PadLeft(3));
        Observer.Observe('text shorter count', T.PadLeft(3));
        Observer.Observe('tc same count', TcHello.PadLeft(17, '*'));
        Observer.Observe('text same count', T.PadLeft(17, '*'));
        Observer.Observe('tc count 0', TcHello.PadLeft(0));
        Observer.Observe('text count 0', T.PadLeft(0));
        asserterror T2 := TcHello.PadLeft(-1);
        Observer.ObserveError('tc negative count');
        asserterror T2 := T.PadLeft(-1);
        Observer.ObserveError('text negative count');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_PadRight()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc default char', TcHello.PadRight(20));
        Observer.Observe('text default char', T.PadRight(20));
        Observer.Observe('tc given char', TcHello.PadRight(20, '*'));
        Observer.Observe('text given char', T.PadRight(20, '*'));
        Observer.Observe('tc shorter count', TcHello.PadRight(3));
        Observer.Observe('text shorter count', T.PadRight(3));
        Observer.Observe('tc same count', TcHello.PadRight(17, '*'));
        Observer.Observe('text same count', T.PadRight(17, '*'));
        Observer.Observe('tc count 0', TcHello.PadRight(0));
        Observer.Observe('text count 0', T.PadRight(0));
        asserterror T2 := TcHello.PadRight(-1);
        Observer.ObserveError('tc negative count');
        asserterror T2 := T.PadRight(-1);
        Observer.ObserveError('text negative count');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_Remove()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc from 7', TcHello.Remove(7));
        Observer.Observe('text from 7', T.Remove(7));
        Observer.Observe('tc from 7 count 6', TcHello.Remove(7, 6));
        Observer.Observe('text from 7 count 6', T.Remove(7, 6));
        Observer.Observe('tc from 1 count 0', TcHello.Remove(1, 0));
        Observer.Observe('text from 1 count 0', T.Remove(1, 0));
        Observer.Observe('tc last char', TcHello.Remove(17, 1));
        Observer.Observe('text last char', T.Remove(17, 1));
        asserterror T2 := TcHello.Remove(0);
        Observer.ObserveError('tc start 0');
        asserterror T2 := T.Remove(0);
        Observer.ObserveError('text start 0');
        asserterror T2 := TcHello.Remove(100);
        Observer.ObserveError('tc start past end');
        asserterror T2 := T.Remove(100);
        Observer.ObserveError('text start past end');
        asserterror T2 := TcHello.Remove(18);
        Observer.ObserveError('tc start after end');
        asserterror T2 := T.Remove(18);
        Observer.ObserveError('text start after end');
        asserterror T2 := TcHello.Remove(7, 100);
        Observer.ObserveError('tc count past end');
        asserterror T2 := T.Remove(7, 100);
        Observer.ObserveError('text count past end');
        asserterror T2 := TcHello.Remove(7, -1);
        Observer.ObserveError('tc negative count');
        asserterror T2 := T.Remove(7, -1);
        Observer.ObserveError('text negative count');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_Replace()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc single match', TcHello.Replace('World', 'There'));
        Observer.Observe('text single match', T.Replace('World', 'There'));
        Observer.Observe('tc repeated match', TcHello.Replace('Hello', 'Bye'));
        Observer.Observe('text repeated match', T.Replace('Hello', 'Bye'));
        Observer.Observe('tc missing', TcHello.Replace('zzz', 'Bye'));
        Observer.Observe('text missing', T.Replace('zzz', 'Bye'));
        Observer.Observe('tc remove by empty', TcHello.Replace('o', ''));
        Observer.Observe('text remove by empty', T.Replace('o', ''));
        Observer.Observe('tc different case', TcHello.Replace('hello', 'Bye'));
        Observer.Observe('text different case', T.Replace('hello', 'Bye'));
        asserterror T2 := TcHello.Replace('', 'x');
        Observer.ObserveError('tc empty old value');
        asserterror T2 := T.Replace('', 'x');
        Observer.ObserveError('text empty old value');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_SplitText()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcSep;
        Observer.Observe('tc default', Join(TcSep.Split()));
        Observer.Observe('text default', Join(T.Split()));
        Observer.Observe('tc comma', Join(TcSep.Split(',')));
        Observer.Observe('text comma', Join(T.Split(',')));
        Observer.Observe('tc comma and semicolon', Join(TcSep.Split(',', ';')));
        Observer.Observe('text comma and semicolon', Join(T.Split(',', ';')));
        Observer.Observe('tc space', Join(TcSep.Split(' ')));
        Observer.Observe('text space', Join(T.Split(' ')));
        Observer.Observe('tc missing separator', Join(TcSep.Split('#')));
        Observer.Observe('text missing separator', Join(T.Split('#')));
        Observer.Observe('tc empty separator', Join(TcSep.Split('')));
        Observer.Observe('text empty separator', Join(T.Split('')));
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_SplitChars()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        C.Add(','); C.Add(';');
        D.Add('#');
        T := TcSep;
        Observer.Observe('tc comma and semicolon', Join(TcSep.Split(C)));
        Observer.Observe('text comma and semicolon', Join(T.Split(C)));
        Observer.Observe('tc missing', Join(TcSep.Split(D)));
        Observer.Observe('text missing', Join(T.Split(D)));
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_SplitTexts()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        L.Add(',,'); L.Add(';');
        M.Add('#');
        T := TcSep;
        Observer.Observe('tc two texts', Join(TcSep.Split(L)));
        Observer.Observe('text two texts', Join(T.Split(L)));
        Observer.Observe('tc missing', Join(TcSep.Split(M)));
        Observer.Observe('text missing', Join(T.Split(M)));
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_StartsWith()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc true', Format(TcHello.StartsWith('Hello')));
        Observer.Observe('text true', Format(T.StartsWith('Hello')));
        Observer.Observe('tc false', Format(TcHello.StartsWith('World')));
        Observer.Observe('text false', Format(T.StartsWith('World')));
        Observer.Observe('tc different case', Format(TcHello.StartsWith('hello')));
        Observer.Observe('text different case', Format(T.StartsWith('hello')));
        Observer.Observe('tc empty value', Format(TcHello.StartsWith('')));
        Observer.Observe('text empty value', Format(T.StartsWith('')));
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_Substring()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcHello;
        Observer.Observe('tc from 7', TcHello.Substring(7));
        Observer.Observe('text from 7', T.Substring(7));
        Observer.Observe('tc from 7 count 5', TcHello.Substring(7, 5));
        Observer.Observe('text from 7 count 5', T.Substring(7, 5));
        Observer.Observe('tc from 1 count 0', TcHello.Substring(1, 0));
        Observer.Observe('text from 1 count 0', T.Substring(1, 0));
        Observer.Observe('tc last char', TcHello.Substring(17, 1));
        Observer.Observe('text last char', T.Substring(17, 1));
        asserterror T2 := TcHello.Substring(0);
        Observer.ObserveError('tc start 0');
        asserterror T2 := T.Substring(0);
        Observer.ObserveError('text start 0');
        asserterror T2 := TcHello.Substring(100);
        Observer.ObserveError('tc start past end');
        asserterror T2 := T.Substring(100);
        Observer.ObserveError('text start past end');
        asserterror T2 := TcHello.Substring(18);
        Observer.ObserveError('tc start after end');
        asserterror T2 := T.Substring(18);
        Observer.ObserveError('text start after end');
        asserterror T2 := TcHello.Substring(7, 100);
        Observer.ObserveError('tc count past end');
        asserterror T2 := T.Substring(7, 100);
        Observer.ObserveError('text count past end');
        asserterror T2 := TcHello.Substring(7, -1);
        Observer.ObserveError('tc negative count');
        asserterror T2 := T.Substring(7, -1);
        Observer.ObserveError('text negative count');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_ToLower()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcMixed;
        Observer.Observe('tc mixed', TcMixed.ToLower());
        Observer.Observe('text mixed', T.ToLower());
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_ToUpper()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T := TcMixed;
        Observer.Observe('tc mixed', TcMixed.ToUpper());
        Observer.Observe('text mixed', T.ToUpper());
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_Trim()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        Observer.Observe('tc spaces both sides', '[' + TcPad.Trim() + ']');
        Observer.Observe('text spaces both sides', '[' + T.Trim() + ']');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_TrimEnd()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T3 := TcPad;
        T := TcChars;
        Observer.Observe('tc default', '[' + TcChars.TrimEnd() + ']');
        Observer.Observe('text default', '[' + T.TrimEnd() + ']');
        Observer.Observe('tc given chars', '[' + TcChars.TrimEnd('x') + ']');
        Observer.Observe('text given chars', '[' + T.TrimEnd('x') + ']');
        Observer.Observe('tc several chars', '[' + TcChars.TrimEnd('cx') + ']');
        Observer.Observe('text several chars', '[' + T.TrimEnd('cx') + ']');
        Observer.Observe('tc char not at end', '[' + TcChars.TrimEnd('a') + ']');
        Observer.Observe('text char not at end', '[' + T.TrimEnd('a') + ']');
        Observer.Observe('tc padded default', '[' + TcPad.TrimEnd() + ']');
        Observer.Observe('text padded default', '[' + T3.TrimEnd() + ']');
        Observer.Finish();
    end;

    [Test]
    procedure TextConst_TrimStart()
    var
        T: Text;
        T2: Text;
        T3: Text;
        I: Integer;
        C: List of [Char];
        D: List of [Char];
        L: List of [Text];
        M: List of [Text];
    begin
        T3 := TcPad;
        T := TcChars;
        Observer.Observe('tc default', '[' + TcChars.TrimStart() + ']');
        Observer.Observe('text default', '[' + T.TrimStart() + ']');
        Observer.Observe('tc given chars', '[' + TcChars.TrimStart('x') + ']');
        Observer.Observe('text given chars', '[' + T.TrimStart('x') + ']');
        Observer.Observe('tc several chars', '[' + TcChars.TrimStart('ax') + ']');
        Observer.Observe('text several chars', '[' + T.TrimStart('ax') + ']');
        Observer.Observe('tc char not at start', '[' + TcChars.TrimStart('c') + ']');
        Observer.Observe('text char not at start', '[' + T.TrimStart('c') + ']');
        Observer.Observe('tc padded default', '[' + TcPad.TrimStart() + ']');
        Observer.Observe('text padded default', '[' + T3.TrimStart() + ']');
        Observer.Finish();
    end;
}
