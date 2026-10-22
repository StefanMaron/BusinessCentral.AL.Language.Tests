// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-publisher-subscriber
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunits 74360 (publisher), 74361 (reader subscriber), 74362 (assigning subscriber), 74363 (assign-first subscriber), 74364 (tests)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a codeunit passes its GLOBAL Boolean, Integer and Text variables as var arguments to an [IntegrationEvent(true, false)] event. A subscriber with var Sender calls a procedure
//   of the sender that sets those globals. What the globals hold after the event, what the subscriber's own parameters hold right after the sender call, and which value wins when
//   the subscriber also assigns a parameter (after the sender call, or before it). Corpus issue 571 (event-var-alias-through-sender).
// BC versions: 29 (27 and 28 by CI)

codeunit 74360 "LT EvVar Pub"
{
    var
        LineCreated: Boolean;
        Counter: Integer;
        Note: Text;

    procedure Start()
    begin
        LineCreated := false;
        Counter := 1;
        Note := 'initial';
    end;

    procedure RaiseWithGlobals()
    begin
        OnWork(LineCreated, Counter, Note);
    end;

    procedure RaiseWithLocals(var LocalCreated: Boolean; var LocalCounter: Integer; var LocalNote: Text)
    begin
        OnWork(LocalCreated, LocalCounter, LocalNote);
    end;

    procedure SetFromSender()
    begin
        LineCreated := true;
        Counter := 5;
        Note := 'set by sender';
    end;

    procedure GetCreated(): Boolean
    begin
        exit(LineCreated);
    end;

    procedure GetCounter(): Integer
    begin
        exit(Counter);
    end;

    procedure GetNote(): Text
    begin
        exit(Note);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnWork(var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
    end;
}

// Calls the sender's procedure and does not assign its own parameters.
codeunit 74361 "LT EvVar Reader Sub"
{
    EventSubscriberInstance = Manual;

    var
        BeforeCreated: Boolean;
        BeforeCount: Integer;
        BeforeText: Text;
        AfterCreated: Boolean;
        AfterCount: Integer;
        AfterText: Text;
        EndCreated: Boolean;
        EndCount: Integer;
        EndText: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        BeforeCreated := Created;
        BeforeCount := Count;
        BeforeText := Txt;
        Sender.SetFromSender();
        AfterCreated := Created;
        AfterCount := Count;
        AfterText := Txt;
        EndCreated := Created;
        EndCount := Count;
        EndText := Txt;
    end;

    procedure Seen(Which: Text): Text
    begin
        case Which of
            'before':
                exit(Format(BeforeCreated) + '/' + Format(BeforeCount) + '/' + BeforeText);
            'after':
                exit(Format(AfterCreated) + '/' + Format(AfterCount) + '/' + AfterText);
        end;
    end;
}

// Calls the sender's procedure, then assigns Count and Txt (not Created).
codeunit 74362 "LT EvVar Assign Sub"
{
    EventSubscriberInstance = Manual;

    var
        AfterSenderCount: Integer;
        AfterSenderText: Text;
        AfterAssignCount: Integer;
        AfterAssignText: Text;
        SenderCounterAfterAssign: Integer;
        SenderNoteAfterAssign: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        Sender.SetFromSender();
        AfterSenderCount := Count;
        AfterSenderText := Txt;
        Count := 99;
        Txt := 'set by subscriber';
        AfterAssignCount := Count;
        AfterAssignText := Txt;
        SenderCounterAfterAssign := Sender.GetCounter();
        SenderNoteAfterAssign := Sender.GetNote();
    end;

    procedure Seen(): Text
    begin
        exit(Format(AfterSenderCount) + '/' + AfterSenderText + '/' + Format(AfterAssignCount) + '/' + AfterAssignText + '/' + Format(SenderCounterAfterAssign) + '/' + SenderNoteAfterAssign);
    end;
}

// Assigns Count and Txt first, then calls the sender's procedure.
codeunit 74363 "LT EvVar AssignFirst Sub"
{
    EventSubscriberInstance = Manual;

    var
        AfterSenderCount: Integer;
        AfterSenderText: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT EvVar Pub", 'OnWork', '', false, false)]
    local procedure OnWork(var Sender: Codeunit "LT EvVar Pub"; var Created: Boolean; var Count: Integer; var Txt: Text)
    begin
        Count := 77;
        Txt := 'assigned first';
        Sender.SetFromSender();
        AfterSenderCount := Count;
        AfterSenderText := Txt;
    end;

    procedure Seen(): Text
    begin
        exit(Format(AfterSenderCount) + '/' + AfterSenderText);
    end;
}

codeunit 74364 "LT EvVar Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure EventVar_GlobalsPassedAsVar_SenderSetsThem_NoAssignInSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar Reader Sub";
    begin
        Pub.Start();
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('globalNote', Pub.GetNote());
        Observer.Observe('paramsBeforeSenderCall', Sub.Seen('before'));
        Observer.Observe('paramsAfterSenderCall', Sub.Seen('after'));
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '5');
        Observer.Expect('globalNote', 'set by sender');
        Observer.Expect('paramsBeforeSenderCall', 'No/1/initial');
        Observer.Expect('paramsAfterSenderCall', 'Yes/5/set by sender');
        Observer.Verify();
    end;

    [Test]
    procedure EventVar_GlobalsPassedAsVar_SubscriberAssignsAfterSenderCall()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar Assign Sub";
    begin
        Pub.Start();
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('globalNote', Pub.GetNote());
        Observer.Observe('subscriberSeen', Sub.Seen());
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '99');
        Observer.Expect('globalNote', 'set by subscriber');
        Observer.Expect('subscriberSeen', '5/set by sender/99/set by subscriber/99/set by subscriber');
        Observer.Verify();
    end;

    [Test]
    procedure EventVar_GlobalsPassedAsVar_SubscriberAssignsBeforeSenderCall()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar AssignFirst Sub";
    begin
        Pub.Start();
        BindSubscription(Sub);
        Pub.RaiseWithGlobals();
        UnbindSubscription(Sub);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('globalNote', Pub.GetNote());
        Observer.Observe('subscriberSeen', Sub.Seen());
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '5');
        Observer.Expect('globalNote', 'set by sender');
        Observer.Expect('subscriberSeen', '5/set by sender');
        Observer.Verify();
    end;

    [Test]
    procedure EventVar_LocalsPassedAsVar_SenderSetsGlobals_LocalsKeepTheirOwnValue()
    var
        Observer: Codeunit "Probe Observer";
        Pub: Codeunit "LT EvVar Pub";
        Sub: Codeunit "LT EvVar Reader Sub";
        LocalCreated: Boolean;
        LocalCounter: Integer;
        LocalNote: Text;
    begin
        // Control: the arguments are caller-owned variables that are not the sender's globals.
        Pub.Start();
        LocalCounter := 10;
        LocalNote := 'local';
        BindSubscription(Sub);
        Pub.RaiseWithLocals(LocalCreated, LocalCounter, LocalNote);
        UnbindSubscription(Sub);
        Observer.Observe('localCreated', Format(LocalCreated));
        Observer.Observe('localCounter', Format(LocalCounter));
        Observer.Observe('localNote', LocalNote);
        Observer.Observe('globalCreated', Format(Pub.GetCreated()));
        Observer.Observe('globalCounter', Format(Pub.GetCounter()));
        Observer.Observe('paramsAfterSenderCall', Sub.Seen('after'));
        Observer.Expect('localCreated', 'No');
        Observer.Expect('localCounter', '10');
        Observer.Expect('localNote', 'local');
        Observer.Expect('globalCreated', 'Yes');
        Observer.Expect('globalCounter', '5');
        Observer.Expect('paramsAfterSenderCall', 'No/10/local');
        Observer.Verify();
    end;
}
