// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: Fixtures.al (interface LT ClT Shape, codeunits 74600/74601, table 74603), codeunit 74615
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List of [Record], List of [Interface], List of [List], List of [Dictionary]: element semantics (copy or reference), equality, nesting.
// BC versions: 29 (27 and 28 by CI)

codeunit 74615 "LT ClT List Complex"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Interface_List()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Interface "LT ClT Shape"];
        C: Codeunit "LT ClT Circle";
        S: Codeunit "LT ClT Square";
        I: Interface "LT ClT Shape";
        Got: Interface "LT ClT Shape";
    begin
        C.SetTag('A');
        I := C;
        L.Add(I);
        I := S;
        L.Add(I);
        Observer.Observe('count', Format(L.Count()));
        Observer.Observe('get 1', L.Get(1).Name());
        Observer.Observe('get 2', L.Get(2).Name());
        C.SetTag('B');
        Observer.Observe('get 1 after retag source', L.Get(1).Name());
        asserterror Observer.Observe('contains I', Format(L.Contains(I)));
        Observer.ObserveError('af33');
        asserterror Observer.Observe('indexof I', Format(L.IndexOf(I)));
        Observer.ObserveError('af35');
        Got := L.Get(1);
        Observer.Observe('got name', Got.Name());
        Observer.Expect('count', '2');
        Observer.Expect('get 1', 'circleA');
        Observer.Expect('get 2', 'square');
        Observer.Expect('get 1 after retag source', 'circleB');
        Observer.Expect('af33|text', 'The function is not supported on lists of type ''Microsoft.Dynamics.Nav.Runtime.NavInterfaceHandle''.');
        Observer.Expect('af33|code', 'NotSupportedOperation');
        Observer.Expect('af35|text', 'The function is not supported on lists of type ''Microsoft.Dynamics.Nav.Runtime.NavInterfaceHandle''.');
        Observer.Expect('af35|code', 'NotSupportedOperation');
        Observer.Expect('got name', 'circleB');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_EqualityDifferentInstances()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Interface "LT ClT Shape"];
        C1: Codeunit "LT ClT Circle";
        C2: Codeunit "LT ClT Circle";
        I: Interface "LT ClT Shape";
    begin
        I := C1;
        L.Add(I);
        I := C2;
        asserterror Observer.Observe('contains other instance', Format(L.Contains(I)));
        Observer.ObserveError('af53');
        asserterror Observer.Observe('indexof other instance', Format(L.IndexOf(I)));
        Observer.ObserveError('af56');
        I := C1;
        asserterror Observer.Observe('contains same instance', Format(L.Contains(I)));
        Observer.ObserveError('af59');
        Observer.Expect('af53|text', 'The function is not supported on lists of type ''Microsoft.Dynamics.Nav.Runtime.NavInterfaceHandle''.');
        Observer.Expect('af53|code', 'NotSupportedOperation');
        Observer.Expect('af56|text', 'The function is not supported on lists of type ''Microsoft.Dynamics.Nav.Runtime.NavInterfaceHandle''.');
        Observer.Expect('af56|code', 'NotSupportedOperation');
        Observer.Expect('af59|text', 'The function is not supported on lists of type ''Microsoft.Dynamics.Nav.Runtime.NavInterfaceHandle''.');
        Observer.Expect('af59|code', 'NotSupportedOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Interface_GetOutOfRange()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Interface "LT ClT Shape"];
        I: Interface "LT ClT Shape";
    begin
        asserterror I := L.Get(1);
        Observer.ObserveError('get on empty');
        Observer.Observe('get out form ret', Format(L.Get(1, I)));
        Observer.Expect('get on empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get on empty|code', 'ArgumentOutOfRange');
        Observer.Expect('get out form ret', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_ListOfList()
    var
        Observer: Codeunit "Probe Observer";
        Outer: List of [List of [Integer]];
        Inner: List of [Integer];
        Got: List of [Integer];
    begin
        Inner.Add(1);
        Outer.Add(Inner);
        Inner.Add(2);
        Outer.Get(1, Got);
        Observer.Observe('inner count after source add', Format(Got.Count()));
        Got.Add(3);
        Observer.Observe('outer inner count after got add', Format(Outer.Get(1).Count()));
        Outer.Add(Inner);
        Observer.Observe('outer count', Format(Outer.Count()));
        Observer.Observe('second inner count', Format(Outer.Get(2).Count()));
        Observer.Observe('contains inner', Format(Outer.Contains(Inner)));
        Observer.Observe('indexof inner', Format(Outer.IndexOf(Inner)));
        Observer.Expect('inner count after source add', '2');
        Observer.Expect('outer inner count after got add', '3');
        Observer.Expect('outer count', '2');
        Observer.Expect('second inner count', '3');
        Observer.Expect('contains inner', 'Yes');
        Observer.Expect('indexof inner', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_ListOfListEquality()
    var
        Observer: Codeunit "Probe Observer";
        Outer: List of [List of [Integer]];
        A: List of [Integer];
        B: List of [Integer];
    begin
        A.Add(1);
        B.Add(1);
        Outer.Add(A);
        asserterror Observer.Observe('contains equal contents other list', Format(Outer.Contains(B)));
        Observer.ObserveError('af108');
        B.Add(2);
        asserterror Observer.Observe('contains different contents', Format(Outer.Contains(B)));
        Observer.ObserveError('af113');
        Observer.Expect('af108|text', 'Unable to compare operands of type NavList`1 with NavList`1.');
        Observer.Expect('af108|code', 'InvalidComparison');
        Observer.Expect('af113|text', 'Unable to compare operands of type NavList`1 with NavList`1.');
        Observer.Expect('af113|code', 'InvalidComparison');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_ListOfDictionary()
    var
        Observer: Codeunit "Probe Observer";
        Outer: List of [Dictionary of [Text, Integer]];
        D: Dictionary of [Text, Integer];
        Got: Dictionary of [Text, Integer];
    begin
        D.Add('a', 1);
        Outer.Add(D);
        D.Add('b', 2);
        Outer.Get(1, Got);
        Observer.Observe('got count', Format(Got.Count()));
        Got.Add('c', 3);
        Observer.Observe('outer elem count', Format(Outer.Get(1).Count()));
        Observer.Observe('source count', Format(D.Count()));
        Observer.Expect('got count', '2');
        Observer.Expect('outer elem count', '3');
        Observer.Expect('source count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Nested_ListOfListOfText()
    var
        Observer: Codeunit "Probe Observer";
        Outer: List of [List of [Text]];
        Inner: List of [Text];
    begin
        Inner.Add('x');
        Outer.Add(Inner);
        Inner.RemoveAt(1);
        Observer.Observe('outer get count', Format(Outer.Get(1).Count()));
        Observer.Expect('outer get count', '0');
        Observer.Verify();
    end;
}
