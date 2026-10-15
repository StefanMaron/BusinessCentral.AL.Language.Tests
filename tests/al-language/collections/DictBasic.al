// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dictionary/dictionary-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74620
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Dictionary of [Text, Integer]: Add, Set, Get (two forms), Remove, ContainsKey, Keys, Values, Count, TryGetValue, Clear-like behaviour, insertion order.
// BC versions: 29 (27 and 28 by CI)

codeunit 74620 "LT ClT Dict Basic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure JoinKeys(D: Dictionary of [Text, Integer]): Text
    var
        K: Text;
        R: Text;
    begin
        foreach K in D.Keys() do
            R += K + ',';
        exit('[' + R + ']');
    end;

    local procedure JoinValues(D: Dictionary of [Text, Integer]): Text
    var
        V: Integer;
        R: Text;
    begin
        foreach V in D.Values() do
            R += Format(V) + ',';
        exit('[' + R + ']');
    end;

    [Test]
    procedure Dict_AddGetCount()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        V: Integer;
        B: Boolean;
    begin
        Observer.Observe('empty count', Format(D.Count()));
        D.Add('b', 2);
        D.Add('a', 1);
        D.Add('c', 3);
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('get a', Format(D.Get('a')));
        B := D.Get('b', V);
        Observer.Observe('get out form ret', Format(B));
        Observer.Observe('get out form val', Format(V));
        V := -1;
        B := D.Get('missing', V);
        Observer.Observe('get missing ret', Format(B));
        Observer.Observe('get missing val', Format(V));
        Observer.Observe('keys order', JoinKeys(D));
        Observer.Observe('values order', JoinValues(D));
        Observer.Expect('empty count', '0');
        Observer.Expect('count', '3');
        Observer.Expect('get a', '1');
        Observer.Expect('get out form ret', 'Yes');
        Observer.Expect('get out form val', '2');
        Observer.Expect('get missing ret', 'No');
        Observer.Expect('get missing val', '-1');
        Observer.Expect('keys order', '[b,a,c,]');
        Observer.Expect('values order', '[2,1,3,]');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_SetRemove()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Add('a', 1);
        D.Add('b', 2);
        D.Set('a', 10);
        Observer.Observe('a', Format(D.Get('a')));
        Observer.Observe('keys after set existing', JoinKeys(D));
        D.Set('c', 3);
        Observer.Observe('count', Format(D.Count()));
        Observer.Observe('keys after set new', JoinKeys(D));
        Observer.Observe('remove existing', Format(D.Remove('b')));
        Observer.Observe('remove missing', Format(D.Remove('b')));
        Observer.Observe('count after remove', Format(D.Count()));
        D.Add('b', 22);
        Observer.Observe('keys after re-add', JoinKeys(D));
        Observer.Observe('values after re-add', JoinValues(D));
        Observer.Expect('a', '10');
        Observer.Expect('keys after set existing', '[a,b,]');
        Observer.Expect('count', '3');
        Observer.Expect('keys after set new', '[a,b,c,]');
        Observer.Expect('remove existing', 'Yes');
        Observer.Expect('remove missing', 'No');
        Observer.Expect('count after remove', '2');
        Observer.Expect('keys after re-add', '[a,b,c,]');
        Observer.Expect('values after re-add', '[10,22,3,]');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_ContainsKey()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        Observer.Observe('empty contains', Format(D.ContainsKey('a')));
        D.Add('a', 0);
        D.Add('', 1);
        Observer.Observe('contains a', Format(D.ContainsKey('a')));
        Observer.Observe('contains empty key', Format(D.ContainsKey('')));
        Observer.Observe('empty key value', Format(D.Get('')));
        Observer.Observe('contains b', Format(D.ContainsKey('b')));
        Observer.Observe('contains a+space', Format(D.ContainsKey('a ')));
        Observer.Observe('contains space', Format(D.ContainsKey(' ')));
        Observer.Expect('empty contains', 'No');
        Observer.Expect('contains a', 'Yes');
        Observer.Expect('contains empty key', 'Yes');
        Observer.Expect('empty key value', '1');
        Observer.Expect('contains b', 'No');
        Observer.Expect('contains a+space', 'No');
        Observer.Expect('contains space', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_ValuesDuplicates()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Add('a', 1);
        D.Add('b', 1);
        D.Add('c', 1);
        Observer.Observe('values', JoinValues(D));
        Observer.Observe('values count', Format(D.Values().Count()));
        Observer.Observe('keys count', Format(D.Keys().Count()));
        Observer.Observe('values contains 1', Format(D.Values().Contains(1)));
        Observer.Observe('values indexof 1', Format(D.Values().IndexOf(1)));
        Observer.Observe('values lastindexof 1', Format(D.Values().LastIndexOf(1)));
        Observer.Observe('keys indexof c', Format(D.Keys().IndexOf('c')));
        Observer.Expect('values', '[1,1,1,]');
        Observer.Expect('values count', '3');
        Observer.Expect('keys count', '3');
        Observer.Expect('values contains 1', 'Yes');
        Observer.Expect('values indexof 1', '1');
        Observer.Expect('values lastindexof 1', '3');
        Observer.Expect('keys indexof c', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_EmptyKeysValues()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        Observer.Observe('keys count', Format(D.Keys().Count()));
        Observer.Observe('values count', Format(D.Values().Count()));
        Observer.Observe('keys', JoinKeys(D));
        Observer.Expect('keys count', '0');
        Observer.Expect('values count', '0');
        Observer.Expect('keys', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_Clear()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
    begin
        D.Add('a', 1);
        Clear(D);
        Observer.Observe('count after Clear()', Format(D.Count()));
        D.Add('a', 2);
        Observer.Observe('re-add after clear', Format(D.Get('a')));
        Observer.Expect('count after Clear()', '0');
        Observer.Expect('re-add after clear', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Dict_InsertionOrderStable()
    var
        Observer: Codeunit "Probe Observer";
        D: Dictionary of [Text, Integer];
        i: Integer;
    begin
        for i := 20 downto 1 do
            D.Add('k' + Format(i), i);
        Observer.Observe('keys', JoinKeys(D));
        D.Remove('k10');
        D.Remove('k1');
        D.Add('k10', 10);
        Observer.Observe('keys after remove and re-add', JoinKeys(D));
        D.Set('k20', 200);
        Observer.Observe('first value', Format(D.Values().Get(1)));
        Observer.Expect('keys', '[k20,k19,k18,k17,k16,k15,k14,k13,k12,k11,k10,k9,k8,k7,k6,k5,k4,k3,k2,k1,]');
        Observer.Expect('keys after remove and re-add', '[k20,k19,k18,k17,k16,k15,k14,k13,k12,k11,k9,k8,k7,k6,k5,k4,k3,k2,k10,]');
        Observer.Expect('first value', '200');
        Observer.Verify();
    end;
}
