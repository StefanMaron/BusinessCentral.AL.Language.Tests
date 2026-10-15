// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/list/list-data-type
// Scope: in-scope
// Fixtures used: self-contained codeunit 74611
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// List of [Integer] error paths: Get/Set/Insert/RemoveAt/RemoveRange/GetRange out of range, empty list, error text and code.
// BC versions: 29 (27 and 28 by CI)

codeunit 74611 "LT ClT List Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Err_GetOutOfRange()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        V: Integer;
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        asserterror V := L.Get(0);
        Observer.ObserveError('get 0');
        asserterror V := L.Get(4);
        Observer.ObserveError('get count+1');
        asserterror V := L.Get(-1);
        Observer.ObserveError('get -1');
        asserterror V := L.Get(2147483647);
        Observer.ObserveError('get maxint');
        asserterror V := L.Get(1000);
        Observer.ObserveError('get 1000');
        Observer.Expect('get 0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get 0|code', 'ArgumentOutOfRange');
        Observer.Expect('get count+1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get count+1|code', 'ArgumentOutOfRange');
        Observer.Expect('get -1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get -1|code', 'ArgumentOutOfRange');
        Observer.Expect('get maxint|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get maxint|code', 'ArgumentOutOfRange');
        Observer.Expect('get 1000|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get 1000|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;

    [Test]
    procedure Err_EmptyList()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        V: Integer;
    begin
        asserterror V := L.Get(1);
        Observer.ObserveError('get 1 on empty');
        asserterror L.Set(1, 5);
        Observer.ObserveError('set 1 on empty');
        asserterror L.RemoveAt(1);
        Observer.ObserveError('removeat 1 on empty');
        asserterror L.RemoveRange(1, 1);
        Observer.ObserveError('removerange 1,1 on empty');
        asserterror L := L.GetRange(1, 1);
        Observer.ObserveError('getrange 1,1 on empty');
        Observer.Observe('insert 1 on empty ret', Format(L.Insert(1, 5)));
        Observer.Observe('count after insert', Format(L.Count()));
        Observer.Expect('get 1 on empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('get 1 on empty|code', 'ArgumentOutOfRange');
        Observer.Expect('set 1 on empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('set 1 on empty|code', 'ArgumentOutOfRange');
        Observer.Expect('removeat 1 on empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removeat 1 on empty|code', 'ArgumentOutOfRange');
        Observer.Expect('removerange 1,1 on empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removerange 1,1 on empty|code', 'Argument');
        Observer.Expect('getrange 1,1 on empty|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange 1,1 on empty|code', 'Argument');
        Observer.Expect('insert 1 on empty ret', 'Yes');
        Observer.Expect('count after insert', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Err_SetInsertRange()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
    begin
        L.Add(1);
        L.Add(2);
        asserterror L.Set(0, 5);
        Observer.ObserveError('set 0');
        asserterror L.Set(3, 5);
        Observer.ObserveError('set count+1');
        asserterror L.Set(-1, 5);
        Observer.ObserveError('set -1');
        asserterror L.Insert(0, 5);
        Observer.ObserveError('insert 0');
        asserterror L.Insert(4, 5);
        Observer.ObserveError('insert count+2');
        asserterror L.Insert(-1, 5);
        Observer.ObserveError('insert -1');
        Observer.Observe('insert count+1 ok', Format(L.Insert(3, 5)));
        Observer.Observe('count', Format(L.Count()));
        Observer.Expect('set 0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('set 0|code', 'ArgumentOutOfRange');
        Observer.Expect('set count+1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('set count+1|code', 'ArgumentOutOfRange');
        Observer.Expect('set -1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('set -1|code', 'ArgumentOutOfRange');
        Observer.Expect('insert 0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('insert 0|code', 'ArgumentOutOfRange');
        Observer.Expect('insert count+2|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('insert count+2|code', 'ArgumentOutOfRange');
        Observer.Expect('insert -1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('insert -1|code', 'ArgumentOutOfRange');
        Observer.Expect('insert count+1 ok', 'Yes');
        Observer.Expect('count', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Err_GetRange()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        R: List of [Integer];
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        asserterror R := L.GetRange(0, 1);
        Observer.ObserveError('getrange 0,1');
        asserterror R := L.GetRange(4, 1);
        Observer.ObserveError('getrange 4,1');
        asserterror R := L.GetRange(2, 3);
        Observer.ObserveError('getrange 2,3 too long');
        asserterror R := L.GetRange(1, -1);
        Observer.ObserveError('getrange 1,-1');
        asserterror R := L.GetRange(-1, 1);
        Observer.ObserveError('getrange -1,1');
        asserterror R := L.GetRange(1, 4);
        Observer.ObserveError('getrange 1,4');
        Observer.Expect('getrange 0,1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange 0,1|code', 'ArgumentOutOfRange');
        Observer.Expect('getrange 4,1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange 4,1|code', 'Argument');
        Observer.Expect('getrange 2,3 too long|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange 2,3 too long|code', 'Argument');
        Observer.Expect('getrange 1,-1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange 1,-1|code', 'ArgumentOutOfRange');
        Observer.Expect('getrange -1,1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange -1,1|code', 'ArgumentOutOfRange');
        Observer.Expect('getrange 1,4|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('getrange 1,4|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Err_GetRangeEdge()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
        R: List of [Integer];
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        R := L.GetRange(3, 1);
        Observer.Observe('getrange 3,1', Format(R.Count()));
        R := L.GetRange(1, 3);
        Observer.Observe('getrange 1,3', Format(R.Count()));
        R := L.GetRange(2, 0);
        Observer.Observe('getrange 2,0', Format(R.Count()));
        R := L.GetRange(4, 0);
        Observer.Observe('getrange 4,0', 'no error');
        Observer.Expect('getrange 3,1', '1');
        Observer.Expect('getrange 1,3', '3');
        Observer.Expect('getrange 2,0', '0');
        Observer.Expect('getrange 4,0', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Err_RemoveRangeBounds()
    var
        Observer: Codeunit "Probe Observer";
        L: List of [Integer];
    begin
        L.Add(1);
        L.Add(2);
        L.Add(3);
        asserterror L.RemoveRange(0, 1);
        Observer.ObserveError('removerange 0,1');
        asserterror L.RemoveRange(4, 1);
        Observer.ObserveError('removerange 4,1');
        asserterror L.RemoveRange(2, 3);
        Observer.ObserveError('removerange 2,3');
        asserterror L.RemoveRange(1, -1);
        Observer.ObserveError('removerange 1,-1');
        asserterror L.RemoveAt(0);
        Observer.ObserveError('removeat 0');
        asserterror L.RemoveAt(4);
        Observer.ObserveError('removeat 4');
        Observer.Observe('count unchanged', Format(L.Count()));
        Observer.Expect('removerange 0,1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removerange 0,1|code', 'ArgumentOutOfRange');
        Observer.Expect('removerange 4,1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removerange 4,1|code', 'Argument');
        Observer.Expect('removerange 2,3|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removerange 2,3|code', 'Argument');
        Observer.Expect('removerange 1,-1|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removerange 1,-1|code', 'ArgumentOutOfRange');
        Observer.Expect('removeat 0|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removeat 0|code', 'ArgumentOutOfRange');
        Observer.Expect('removeat 4|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('removeat 4|code', 'ArgumentOutOfRange');
        Observer.Expect('count unchanged', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Err_UninitialisedAndTextOverflow()
    var
        Observer: Codeunit "Probe Observer";
        LT: List of [Text[3]];
        LC: List of [Code[3]];
    begin
        asserterror LT.Add('abcdef');
        Observer.ObserveError('af161');
        asserterror Observer.Observe('text[3] add long', LT.Get(1));
        Observer.ObserveError('af163');
        asserterror LC.Add('abcdef');
        Observer.ObserveError('af165');
        asserterror Observer.Observe('code[3] add long', LC.Get(1));
        Observer.ObserveError('af167');
        LC.Add('xy');
        asserterror Observer.Observe('code lowercased', LC.Get(2));
        Observer.ObserveError('af170');
        Observer.Expect('af161|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('af161|code', 'StringLengthExceeded');
        Observer.Expect('af163|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('af163|code', 'ArgumentOutOfRange');
        Observer.Expect('af165|text', 'The length of the string is 6, but it must be less than or equal to 3 characters. Value: abcdef');
        Observer.Expect('af165|code', 'StringLengthExceeded');
        Observer.Expect('af167|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('af167|code', 'ArgumentOutOfRange');
        Observer.Expect('af170|text', 'An invalid argument was passed to a ''List'' data type method.');
        Observer.Expect('af170|code', 'ArgumentOutOfRange');
        Observer.Verify();
    end;
}
