// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74612
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// AddRange: the list form and the value-list (array) form, empty, self, copy.
// BC versions: 29 (27 and 28 by CI)

codeunit 74612 "LT ClT List AddRange"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Join(L: List of [Integer]): Text
    var
        i: Integer;
        R: Text;
    begin
        for i := 1 to L.Count() do begin
            if i > 1 then
                R += ',';
            R += Format(L.Get(i));
        end;
        exit('[' + R + ']');
    end;

    [Test]
    procedure AddRange_List()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
        B: List of [Integer];
        Empty: List of [Integer];
    begin
        A.Add(1);
        A.Add(2);
        B.Add(3);
        B.Add(4);
        A.AddRange(B);
        Observer.Observe('a after', Join(A));
        Observer.Observe('b unchanged', Join(B));
        A.AddRange(Empty);
        Observer.Observe('add empty', Join(A));
        Empty.AddRange(B);
        Observer.Observe('empty gets b', Join(Empty));
        B.Add(5);
        Observer.Observe('a not tied to b', Join(A));
        Observer.Expect('a after', '[1,2,3,4]');
        Observer.Expect('b unchanged', '[3,4]');
        Observer.Expect('add empty', '[1,2,3,4]');
        Observer.Expect('empty gets b', '[3,4]');
        Observer.Expect('a not tied to b', '[1,2,3,4]');
        Observer.Verify();
    end;

    [Test]
    procedure AddRange_Self()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
    begin
        A.Add(1);
        A.Add(2);
        A.AddRange(A);
        Observer.Observe('self add', Join(A));
        Observer.Observe('count', Format(A.Count()));
        Observer.Expect('self add', '[1,2,1,2]');
        Observer.Expect('count', '4');
        Observer.Verify();
    end;

    [Test]
    procedure AddRange_Values()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Integer];
    begin
        A.AddRange(1, 2, 3);
        Observer.Observe('values', Join(A));
        A.AddRange(9);
        Observer.Observe('single value', Join(A));
        Observer.Expect('values', '[1,2,3]');
        Observer.Expect('single value', '[1,2,3,9]');
        Observer.Verify();
    end;

    [Test]
    procedure AddRange_TextValues()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Text];
    begin
        A.AddRange('a', 'b', 'c');
        Observer.Observe('count', Format(A.Count()));
        Observer.Observe('last', A.Get(3));
        Observer.Expect('count', '3');
        Observer.Expect('last', 'c');
        Observer.Verify();
    end;

    [Test]
    procedure AddRange_Mixed()
    var
        Observer: Codeunit "Probe Observer";
        A: List of [Decimal];
        B: List of [Integer];
    begin
        A.AddRange(1, 2.5);
        Observer.Observe('decimal list from ints', Format(A.Get(1)) + '|' + Format(A.Get(2)));
        B.Add(1);
        Observer.Expect('decimal list from ints', '1|2.5');
        Observer.Verify();
    end;
}
