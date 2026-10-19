// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-isolated
// Scope: in-scope
// Fixtures used: CkEventObjects.al and CkEventPermObjects.al in this folder (84700-84711), shared Assert (60021), Permissions Mock.
// Facts: corpus issue 669 (odd AL behavior leads, part D), items 3, 4, 5, 8, 9, 10, 11, 12, 14, 15. Each test binds its own
//   manual subscriber codeunit, raises one event and asserts one result string with what BC returned.
// BC versions: 27, 28, 29

codeunit 84712 "LT CK Event Leads"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Log: Codeunit "LT CK Ev Log";

    // Item 10: the publisher passes Enum C (ordinal 5); the subscriber declares Option A,B,C (compile warning AL0588).
    [Test]
    procedure EnumParameter_ReceivedAsOption()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
    begin
        Log.Reset();
        BindSubscription(Subs);
        Assert.AreEqual('OBS', TryOutcome(1, Pub) + '|' + Log.Text(), 'Enum C (5) received as Option A,B,C');
    end;

    // Item 10: Enum B (ordinal 1).
    [Test]
    procedure EnumParameter_ReceivedAsOption_InRange()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
    begin
        Log.Reset();
        BindSubscription(Subs);
        Assert.AreEqual('OBS', TryOutcome(2, Pub) + '|' + Log.Text(), 'Enum B (1) received as Option A,B,C');
    end;

    // Item 11: the publisher's Option A,B,C value B (1) and C (2), the subscriber declares Option X,Y (no diagnostic).
    [Test]
    procedure OptionParameter_ReceivedAsOptionWithOtherMembers()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
    begin
        Log.Reset();
        BindSubscription(Subs);
        Assert.AreEqual('OBS', TryOutcome(3, Pub) + '|' + TryOutcome(4, Pub) + '|' + Log.Text(), 'Option B and C received as Option X,Y');
    end;

    // Item 12: Text[100] publisher, Text[30] subscriber (warning AL0593); 50 characters in, by value and var.
    [Test]
    procedure TextParameter_SubscriberSmallerCapacity()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
        VT: Text[100];
    begin
        Log.Reset();
        BindSubscription(Subs);
        VT := PadStr('', 50, 'v');
        Assert.AreEqual('OBS', TryText(Pub, PadStr('', 50, 't'), VT) + '|' + Log.Text() + '|' + VT, 'Text[30] subscriber, 50 characters');
    end;

    // Item 12: the same with 20 characters (fits both capacities).
    [Test]
    procedure TextParameter_SubscriberSmallerCapacity_Fits()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
        VT: Text[100];
    begin
        Log.Reset();
        BindSubscription(Subs);
        VT := PadStr('', 20, 'v');
        Assert.AreEqual('OBS', TryText(Pub, PadStr('', 20, 't'), VT) + '|' + Log.Text() + '|' + VT, 'Text[30] subscriber, 20 characters');
    end;

    // Item 15: the publisher passes var Handled; the subscriber declares Handled without var and assigns true.
    [Test]
    procedure VarParameter_SubscriberWithoutVar()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
        AfterFalse: Boolean;
        AfterTrue: Boolean;
    begin
        Log.Reset();
        BindSubscription(Subs);
        AfterFalse := Pub.RaiseHandled(false);
        AfterTrue := Pub.RaiseHandled(true);
        Assert.AreEqual('OBS', Format(AfterFalse) + '|' + Format(AfterTrue) + '|' + Log.Text(), 'Handled without var');
    end;

    // Item 5: GlobalVarAccess. The subscriber reads the publisher's global G by name, and a var G writes back.
    [Test]
    procedure GlobalVarAccess_ReadAndWriteBack()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Subs: Codeunit "LT CK Ev Subs";
    begin
        Log.Reset();
        BindSubscription(Subs);
        Pub.SetG(41);
        Pub.RaiseGlobalRead();
        Pub.RaiseGlobalWrite();
        Assert.AreEqual('OBS', Log.Text() + '|' + Format(Pub.GetG()), 'GlobalVarAccess read and var write');
    end;

    // Item 14: table event subscribers with reordered parameters, names in another case, and a subset (no xRec).
    [Test]
    procedure TableEventSubscriber_ReorderedCaseAndSubset()
    var
        Subs: Codeunit "LT CK Ev Subs";
        Row: Record "LT CK Ev Row";
        Stored: Record "LT CK Ev Row";
    begin
        Row.DeleteAll();
        Log.Reset();
        BindSubscription(Subs);
        Row.Id := 1;
        Row.Insert(true);
        Row.Validate(Val, 20);
        Stored.Get(1);
        Assert.AreEqual('OBS', Log.Text() + '|' + Format(Row.Val) + '|' + Format(Stored.Val), 'reordered, other case and subset parameters');
    end;

    // Item 3: Scope OnPrem subscriber (warning AL0635) on a Cloud publisher, in a Cloud app.
    [Test]
    procedure OnPremScopedSubscriber_CloudPublisher()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Sub: Codeunit "LT CK Ev OnPrem Sub";
    begin
        BindSubscription(Sub);
        Assert.AreEqual('OBS', TryOutcome(5, Pub), 'OnPrem-scoped subscriber');
    end;

    // Item 8: an event without subscribers returns normally, the var argument unchanged.
    [Test]
    procedure EventWithoutSubscribers_ReturnsNormally()
    var
        Pub: Codeunit "LT CK Ev Pub";
    begin
        Assert.AreEqual(3, Pub.RaiseNoSubscribers(), 'An event without subscribers leaves the var argument as it was');
    end;

    // Item 8: OnOpenPageEvent subscriber on a page without SourceTable.
    [Test]
    procedure PageWithoutSourceTable_OnOpenPageEventFires()
    var
        Sub: Codeunit "LT CK Ev Page Sub";
        TP: TestPage "LT CK Ev NoSrc";
    begin
        Log.Reset();
        BindSubscription(Sub);
        TP.OpenView();
        TP.Close();
        Assert.AreEqual('OBS', Log.Text(), 'OnOpenPageEvent of a page without SourceTable');
    end;

    // Item 9: a failing isolated subscriber: the var argument, a SingleInstance member, and its table write.
    [Test]
    procedure IsolatedEvent_FailingSubscriber_VariablesAndSingleInstance()
    var
        Pub: Codeunit "LT CK Ev Pub";
        Sub: Codeunit "LT CK Ev Iso Sub";
        Row: Record "LT CK Ev Row";
        Counter: Integer;
    begin
        Row.DeleteAll();
        Commit();
        Log.Reset();
        BindSubscription(Sub);
        ClearLastError();
        Counter := Pub.RaiseIsolated();
        Assert.AreEqual('OBS', Format(Counter) + '|' + Format(Log.GetMember()) + '|' + Log.Text() + '|' + Format(Row.Get(84706)) + '|' + GetLastErrorText(), 'failing isolated subscriber');
    end;

    // Item 4: SkipOnMissingPermission = false; the effective set does not grant Execute on the subscriber codeunit.
    [Test]
    procedure MissingExecutePermission_StrictSubscriber()
    var
        Strict: Codeunit "LT CK Ev Perm Sub Strict";
    begin
        BindSubscription(Strict);
        Assert.AreEqual('OBS', RunUnderPermSet(), 'subscriber without Execute permission, SkipOnMissingPermission false');
    end;

    // Item 4: SkipOnMissingPermission = true.
    [Test]
    procedure MissingExecutePermission_SkippingSubscriber()
    var
        Skip: Codeunit "LT CK Ev Perm Sub Skip";
    begin
        BindSubscription(Skip);
        Assert.AreEqual('OBS', RunUnderPermSet(), 'subscriber without Execute permission, SkipOnMissingPermission true');
    end;

    local procedure RunUnderPermSet() Result: Text
    var
        PermissionsMock: Codeunit "Permissions Mock";
        Pub: Codeunit "LT CK Ev Pub";
        WasStarted: Boolean;
    begin
        WasStarted := PermissionsMock.IsStarted();
        if not WasStarted then
            PermissionsMock.Start();
        PermissionsMock.Set('LT CK Ev Perm');
        Result := TryOutcome(6, Pub);
        PermissionsMock.ClearAssignments();
        if not WasStarted then
            PermissionsMock.Stop();
    end;

    local procedure TryOutcome(Which: Integer; var Pub: Codeunit "LT CK Ev Pub"): Text
    var
        Value: Integer;
    begin
        ClearLastError();
        if TryRaise(Which, Pub, Value) then
            exit('ok:' + Format(Value));
        exit('err:' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
    end;

    [TryFunction]
    local procedure TryRaise(Which: Integer; var Pub: Codeunit "LT CK Ev Pub"; var Value: Integer)
    begin
        case Which of
            1:
                Pub.RaiseEnum("LT CK Ev Enum"::C);
            2:
                Pub.RaiseEnum("LT CK Ev Enum"::B);
            3:
                Pub.RaiseOption(1);
            4:
                Pub.RaiseOption(2);
            5:
                Value := Pub.RaiseScoped();
            6:
                Value := Pub.RaisePerm();
        end;
    end;

    local procedure TryText(var Pub: Codeunit "LT CK Ev Pub"; Value: Text[100]; var VT: Text[100]): Text
    begin
        ClearLastError();
        if TryRaiseText(Pub, Value, VT) then
            exit('ok');
        exit('err:' + GetLastErrorText() + ' [' + GetLastErrorCode() + ']');
    end;

    [TryFunction]
    local procedure TryRaiseText(var Pub: Codeunit "LT CK Ev Pub"; Value: Text[100]; var VT: Text[100])
    begin
        Pub.RaiseText(Value, VT);
    end;
}
