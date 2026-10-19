// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: Probe Observer, ALTPermissionSet (grants "ALT Universal" only), "ALT No Subscriber Table" (60590), "Permissions Mock" (System Application Test Library)
// Probe: corpus issue 670 item 15: with "if Rec.Get(...)" (result used), does a missing read permission still raise an error?
//   Every literal asserted below is what BC produced; the CI matrix checks BC 27.5, 28.5 and 29.0.
// BC versions: 27, 28, 29

codeunit 85181 "LT CS Record Get"
{
    Subtype = Test;

    [TryFunction]
    local procedure TryPlainGet(var Row: Record "ALT No Subscriber Table"; EntryNo: Integer)
    begin
        Row.Get(EntryNo);
    end;

    [TryFunction]
    local procedure TryFindFirst(var Row: Record "ALT No Subscriber Table")
    begin
        Row.Reset();
        Row.FindFirst();
    end;

    [TryFunction]
    local procedure TryModify(var Row: Record "ALT No Subscriber Table")
    begin
        Row.Value := 2;
        Row.Modify();
    end;

    local procedure Outcome(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit('error: ' + GetLastErrorText() + ' code: ' + GetLastErrorCode());
    end;

    [Test]
    procedure RecordGet_ResultUsed_NoReadPermission()
    var
        Observer: Codeunit "Probe Observer";
        PermissionsMock: Codeunit "Permissions Mock";
        Row: Record "ALT No Subscriber Table";
        WasStarted: Boolean;
        Found: Boolean;
    begin
        if Row.Get(851810) then
            Row.Delete();
        Row.Init();
        Row."Entry No." := 851810;
        Row.Value := 1;
        Row.Insert();
        WasStarted := PermissionsMock.IsStarted();
        if not WasStarted then
            PermissionsMock.Start();
        PermissionsMock.Set('ALTPermissionSet');
        ClearLastError();
        Found := Row.Get(851810);
        Observer.Observe('existing row result', Format(Found));
        Observer.Observe('existing row last error', GetLastErrorText());
        Observer.Observe('existing row value', Format(Row.Value));
        Found := Row.Get(851811);
        Observer.Observe('missing row result', Format(Found));
        Observer.Observe('plain get', Outcome(TryPlainGet(Row, 851810)));
        Observer.Observe('findfirst', Outcome(TryFindFirst(Row)));
        Observer.Observe('modify', Outcome(TryModify(Row)));
        PermissionsMock.ClearAssignments();
        if not WasStarted then
            PermissionsMock.Stop();
        Observer.Observe('after restore', Format(Row.Get(851810)));
        Row.Delete();
        Observer.Finish();
    end;
}
