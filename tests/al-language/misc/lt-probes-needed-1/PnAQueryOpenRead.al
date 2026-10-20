// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of PnAQueryObjects.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Query: Open does not run the query: the first Read does, with the filters set at that time; SetRange and Open after a Read
// Facts: when a Query takes its filters: SetRange between Open and the first Read, SetRange and Open after a Read, Close then SetRange then Open
// BC versions: 29 (27 and 28 by CI)

codeunit 70128 "LT PnA Q OpenRead"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Q: Query "LT PnA Q Plain";

    local procedure Seed()
    var
        S: Record "LT PnA Q Src";
        i: Integer;
    begin
        S.DeleteAll();
        for i := 1 to 5 do begin
            S.Entry := i;
            S.Grp := 'G';
            S.Name := 'n' + Format(i);
            S.Qty := i;
            S.Insert();
        end;
    end;

    [TryFunction]
    local procedure TryOp(Op: Integer; Arg: Integer)
    begin
        case Op of
            1:
                Q.SetRange(Entry, Arg);
            2:
                Q.Open();
            3:
                Q.Close();
            4:
                Q.SetRange(Qty, Arg);
            5:
                Q.SetFilter(Entry, '>%1', Arg);
        end;
    end;

    local procedure Op(var Observer: Codeunit "Probe Observer"; Name: Text; OpNo: Integer; Arg: Integer)
    begin
        Observer.Observe(Name, Format(TryOp(OpNo, Arg)));
        Observer.ObserveError(Name);
    end;

    local procedure ReadAll(): Text
    var
        R: Text;
    begin
        while Q.Read() do
            R += Format(Q.Entry) + ',';
        exit(R);
    end;

    [Test]
    procedure SetRangeBetweenOpenAndFirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'open', 2, 0);
        Op(Observer, 'setrange-after-open', 1, 3);
        asserterror Observer.Observe('rows', ReadAll());
        Observer.ObserveError('af73');
        Op(Observer, 'close', 3, 0);
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('setrange-after-open', 'Yes');
        Observer.Expect('setrange-after-open|text', '');
        Observer.Expect('setrange-after-open|code', '');
        Observer.Expect('af73|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af73|code', 'Query');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRangeBeforeOpen_ThenChangedBeforeFirstRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'setrange-before', 1, 2);
        Op(Observer, 'open', 2, 0);
        Op(Observer, 'setrange-after-open', 1, 4);
        asserterror Observer.Observe('rows', ReadAll());
        Observer.ObserveError('af89');
        asserterror Observer.Observe('read-after-end', Format(Q.Read()));
        Observer.ObserveError('af91');
        Op(Observer, 'close', 3, 0);
        Observer.Expect('setrange-before', 'Yes');
        Observer.Expect('setrange-before|text', '');
        Observer.Expect('setrange-before|code', '');
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('setrange-after-open', 'Yes');
        Observer.Expect('setrange-after-open|text', '');
        Observer.Expect('setrange-after-open|code', '');
        Observer.Expect('af89|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af89|code', 'Query');
        Observer.Expect('af91|text', 'The READ function is called on a query after query metadata has been changed by one of the following: SETFILTER, SETRANGE, SECURITYFILTERING, or TOPNUMBEROFROWS. After metadata changes, you must reopen the query by calling the OPEN function before calling the READ function.');
        Observer.Expect('af91|code', 'Query');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure SetRangeAndOpenAfterRead()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'open', 2, 0);
        Observer.Observe('first-read', Format(Q.Read()));
        Observer.Observe('first-entry', Format(Q.Entry));
        Op(Observer, 'setrange-after-read', 1, 4);
        Op(Observer, 'setrange-other-field-after-read', 4, 4);
        Op(Observer, 'setfilter-after-read', 5, 3);
        Op(Observer, 'open-after-read', 2, 0);
        Observer.Observe('next-read', Format(Q.Read()));
        Observer.Observe('next-entry', Format(Q.Entry));
        Op(Observer, 'close', 3, 0);
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('first-read', 'Yes');
        Observer.Expect('first-entry', '1');
        Observer.Expect('setrange-after-read', 'Yes');
        Observer.Expect('setrange-after-read|text', '');
        Observer.Expect('setrange-after-read|code', '');
        Observer.Expect('setrange-other-field-after-read', 'Yes');
        Observer.Expect('setrange-other-field-after-read|text', '');
        Observer.Expect('setrange-other-field-after-read|code', '');
        Observer.Expect('setfilter-after-read', 'Yes');
        Observer.Expect('setfilter-after-read|text', '');
        Observer.Expect('setfilter-after-read|code', '');
        Observer.Expect('open-after-read', 'Yes');
        Observer.Expect('open-after-read|text', '');
        Observer.Expect('open-after-read|code', '');
        Observer.Expect('next-read', 'Yes');
        Observer.Expect('next-entry', '4');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure CloseSetRangeReopen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Op(Observer, 'open', 2, 0);
        Observer.Observe('first-read', Format(Q.Read()));
        Op(Observer, 'close', 3, 0);
        Op(Observer, 'setrange-after-close', 1, 4);
        Op(Observer, 'open-again', 2, 0);
        Observer.Observe('rows', ReadAll());
        Op(Observer, 'close-again', 3, 0);
        Op(Observer, 'close-twice', 3, 0);
        Observer.Observe('read-closed', Format(Q.Read()));
        Op(Observer, 'open-third', 2, 0);
        Observer.Observe('rows-third', ReadAll());
        Op(Observer, 'open-while-open', 2, 0);
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('first-read', 'Yes');
        Observer.Expect('close', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Expect('setrange-after-close', 'Yes');
        Observer.Expect('setrange-after-close|text', '');
        Observer.Expect('setrange-after-close|code', '');
        Observer.Expect('open-again', 'Yes');
        Observer.Expect('open-again|text', '');
        Observer.Expect('open-again|code', '');
        Observer.Expect('rows', '4,');
        Observer.Expect('close-again', 'Yes');
        Observer.Expect('close-again|text', '');
        Observer.Expect('close-again|code', '');
        Observer.Expect('close-twice', 'Yes');
        Observer.Expect('close-twice|text', '');
        Observer.Expect('close-twice|code', '');
        Observer.Expect('read-closed', 'No');
        Observer.Expect('open-third', 'Yes');
        Observer.Expect('open-third|text', '');
        Observer.Expect('open-third|code', '');
        Observer.Expect('rows-third', '4,');
        Observer.Expect('open-while-open', 'Yes');
        Observer.Expect('open-while-open|text', '');
        Observer.Expect('open-while-open|code', '');
        Observer.Verify();
    end;

    // Writer PX (probes-needed "Query": TopNumberOfRows and SecurityFiltering after Open are not pinned): each call between Open and the first
    // Read, after a Read, and before Open, then the rows read (5 rows of Seed, Entry 1..5).
    [TryFunction]
    local procedure PxTryTop(N: Integer)
    begin
        Q.TopNumberOfRows(N);
    end;

    [TryFunction]
    local procedure PxTrySecurity()
    begin
        Q.SecurityFiltering(SecurityFilter::Filtered);
    end;

    [TryFunction]
    local procedure PxTryReadAll(var Rows: Text)
    begin
        Rows := ReadAll();
    end;

    local procedure PxRead(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Rows: Text;
    begin
        Observer.Observe(Name, Format(PxTryReadAll(Rows)) + ' ' + Rows);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure PX_TopNumberOfRows_AroundOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Q.Open();
        Observer.Observe('top-after-open', Format(PxTryTop(2)));
        Observer.ObserveError('top-after-open');
        PxRead(Observer, 'read-after-top');
        Q.Close();
        Clear(Q);
        Q.TopNumberOfRows(2);
        Q.Open();
        PxRead(Observer, 'top-before-open');
        Clear(Q);
        Q.Open();
        Observer.Observe('first-read', Format(Q.Read()));
        Observer.Observe('top-after-read', Format(PxTryTop(1)));
        Observer.ObserveError('top-after-read');
        PxRead(Observer, 'read-after-top-after-read');
        Q.Open();
        PxRead(Observer, 'reopen-after-top');
        Observer.Finish();
    end;

    [Test]
    procedure PX_SecurityFiltering_AroundOpen()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Clear(Q);
        Q.Open();
        Observer.Observe('security-after-open', Format(PxTrySecurity()));
        Observer.ObserveError('security-after-open');
        PxRead(Observer, 'read-after-security');
        Q.Close();
        Clear(Q);
        Q.Open();
        Observer.Observe('first-read', Format(Q.Read()));
        Observer.Observe('security-after-read', Format(PxTrySecurity()));
        Observer.ObserveError('security-after-read');
        PxRead(Observer, 'read-after-security-after-read');
        Q.Open();
        PxRead(Observer, 'reopen-after-security');
        Observer.Observe('security-value', Format(Q.SecurityFiltering()));
        Observer.Finish();
    end;
}
