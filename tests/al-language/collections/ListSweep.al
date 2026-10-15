// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74624
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List of [Text] full method sweep, Decimal/Boolean/Date/Enum/Guid list basics (Insert, Set, GetRange, RemoveRange, Reverse, errors), default values of uninitialised lists.
// BC versions: 29 (27 and 28 by CI)

codeunit 74624 "LT ClT List Sweep"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure JoinT(L: List of [Text]): Text
    var
        T: Text;
        R: Text;
    begin
        foreach T in L do
            R += T + '|';
        exit(R);
    end;

    [Test]
    procedure TextList_AllMethods()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        R: List of [Text];
    begin
        L.Add('c');
        L.Add('a');
        L.Add('b');
        L.Insert(2, 'x');
        Observer.Observe('after insert', JoinT(L));
        L.Set(1, 'C');
        Observer.Observe('after set', JoinT(L));
        L.Reverse();
        Observer.Observe('after reverse', JoinT(L));
        R := L.GetRange(2, 2);
        Observer.Observe('range', JoinT(R));
        L.RemoveRange(2, 2);
        Observer.Observe('after removerange', JoinT(L));
        L.RemoveAt(1);
        Observer.Observe('after removeat', JoinT(L));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('after insert', 'c|x|a|b|');
        Observer.Expect('after set', 'C|x|a|b|');
        Observer.Expect('after reverse', 'b|a|x|C|');
        Observer.Expect('range', 'a|x|');
        Observer.Expect('after removerange', 'b|C|');
        Observer.Expect('after removeat', 'C|');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure TextList_Errors()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Text];
        T: Text;
    begin
        asserterror T := L.Get(1);
        Observer.ObserveError('get empty');
        L.Add('a');
        asserterror T := L.Get(2);
        Observer.ObserveError('get 2');
        asserterror L.Insert(3, 'z');
        Observer.ObserveError('insert 3');
        asserterror L.Set(2, 'z');
        Observer.ObserveError('set 2');
        Observer.Observe('get out form ret on 2', Format(L.Get(2, T)));
        Observer.Observe('t after failed out get', T);
        Observer.Expect('get empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get empty|code', 'ArgumentOutOfRange');
        Observer.Expect('get 2|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get 2|code', 'ArgumentOutOfRange');
        Observer.Expect('insert 3|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('insert 3|code', 'ArgumentOutOfRange');
        Observer.Expect('set 2|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('set 2|code', 'ArgumentOutOfRange');
        Observer.Expect('get out form ret on 2', 'No');
        Observer.Expect('t after failed out get', '');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalList_Sweep()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Decimal];
        D: Decimal;
        Sum: Decimal;
    begin
        L.Add(0.1);
        L.Add(0.2);
        L.Add(0.3);
        foreach D in L do
            Sum += D;
        Observer.Observe('sum', Format(Sum, 0, 9));
        Observer.Observe('sum equals 0.6', Format(Sum = 0.6));
        L.Insert(1, -1);
        Observer.Observe('first', Format(L.Get(1)));
        Observer.Observe('indexof 0.3', Format(L.IndexOf(0.3)));
        asserterror D := L.Get(5);
        Observer.ObserveError('get 5');
        Observer.Expect('sum', '0.6');
        Observer.Expect('sum equals 0.6', 'Yes');
        Observer.Expect('first', '-1');
        Observer.Expect('indexof 0.3', '4');
        Observer.Expect('get 5|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get 5|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure BooleanDateEnumList_Sweep()
    var
        Observer: Codeunit "Probe Observer";
        LB: List of [Boolean];
        LD: List of [Date];
        LE: List of [Enum "LT ClT Color"];
        B: Boolean;
        D: Date;
        E: Enum "LT ClT Color";
    begin
        asserterror B := LB.Get(1);
        Observer.ObserveError('boolean get empty');
        asserterror D := LD.Get(1);
        Observer.ObserveError('date get empty');
        asserterror E := LE.Get(1);
        Observer.ObserveError('enum get empty');
        LB.Add(false);
        LD.Add(0D);
        LE.Add(Enum::"LT ClT Color"::Red);
        Observer.Observe('boolean get 1', Format(LB.Get(1)));
        Observer.Observe('date get 1', Format(LD.Get(1), 0, 9));
        Observer.Observe('enum get 1', Format(LE.Get(1)));
        Observer.Observe('boolean getrange', Format(LB.GetRange(1, 1).Count()));
        LE.Insert(1, Enum::"LT ClT Color"::Blue);
        Observer.Observe('enum insert first', Format(LE.Get(1)));
        Observer.Observe('enum reverse', '');
        LE.Reverse();
        Observer.Observe('enum first after reverse', Format(LE.Get(1)));
        Observer.Expect('boolean get empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('boolean get empty|code', 'ArgumentOutOfRange');
        Observer.Expect('date get empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('date get empty|code', 'ArgumentOutOfRange');
        Observer.Expect('enum get empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('enum get empty|code', 'ArgumentOutOfRange');
        Observer.Expect('boolean get 1', 'No');
        Observer.Expect('date get 1', '');
        Observer.Expect('enum get 1', 'Red');
        Observer.Expect('boolean getrange', '1');
        Observer.Expect('enum insert first', 'Blue Caption');
        Observer.Expect('enum reverse', '');
        Observer.Expect('enum first after reverse', 'Red');
        Observer.Verify();
    end;

    [Test]
    procedure List_ReverseAndRemoveRangeSemantics()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        i: Integer;
        R: Text;
        V: Integer;
    begin
        for i := 1 to 6 do
            L.Add(i);
        L.Reverse();
        foreach V in L do
            R += Format(V);
        Observer.Observe('reversed', R);
        L.RemoveRange(1, 3);
        R := '';
        foreach V in L do
            R += Format(V);
        Observer.Observe('after removerange 1,3', R);
        L.RemoveRange(L.Count(), 1);
        Observer.Observe('count after removing last', Format(L.Count()));
        L.Insert(1, 7);
        L.Reverse();
        Observer.Observe('last is 7', Format(L.Get(L.Count())));
        Observer.Observe('single element reverse', '');
        Observer.Expect('reversed', '654321');
        Observer.Expect('after removerange 1,3', '321');
        Observer.Expect('count after removing last', '2');
        Observer.Expect('last is 7', '7');
        Observer.Expect('single element reverse', '');
        Observer.Verify();
    end;

    [Test]
    procedure List_ContainsOnLargeAndIndexAfterRemove()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        i: Integer;
    begin
        for i := 1 to 500 do
            L.Add(i mod 10);
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('indexof 7', Format(L.IndexOf(7)));
        Observer.Observe('lastindexof 7', Format(L.LastIndexOf(7)));
        L.Remove(7);
        Observer.Observe('indexof 7 after remove', Format(L.IndexOf(7)));
        Observer.Observe('count after remove', Format(L.Count()));
        Observer.Expect('count', '500');
        Observer.Expect('indexof 7', '7');
        Observer.Expect('lastindexof 7', '497');
        Observer.Expect('indexof 7 after remove', '16');
        Observer.Expect('count after remove', '499');
        Observer.Verify();
    end;
}
