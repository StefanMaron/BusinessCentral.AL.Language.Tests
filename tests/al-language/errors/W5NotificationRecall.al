// Batch 5, md:554 (Notification): a second Recall, a recall handler answering false, Recall with no handler twice.
// Handlers are declared only where the test surely triggers them (Send always runs the send handler; the first Recall of a sent notification runs the recall handler).

codeunit 67049 "W5 Notification Recall Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;

    [SendNotificationHandler]
    procedure SendHandler(var Notif: Notification): Boolean
    begin
        HandlerLog += 'send;';
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure RecallAnswersTrue(var Notif: Notification): Boolean
    begin
        HandlerLog += 'recall(true);';
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure RecallAnswersFalse(var Notif: Notification): Boolean
    begin
        HandlerLog += 'recall(false);';
        exit(false);
    end;

    [Test]
    [HandlerFunctions('SendHandler,RecallAnswersTrue')]
    procedure Recall_Twice_HandlerAnswersTrue()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
        First: Boolean;
        Second: Boolean;
    begin
        HandlerLog := '';
        Notif.Message('w5 recall twice');
        Notif.Send();
        First := Notif.Recall();
        Second := Notif.Recall();
        Observer.Observe('first_recall', Format(First));
        Observer.Observe('second_recall', Format(Second));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Expect('first_recall', 'Yes');
        Observer.Expect('second_recall', 'Yes');
        Observer.Expect('handler_log', 'send;recall(true);recall(true);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SendHandler,RecallAnswersFalse')]
    procedure Recall_HandlerAnswersFalse()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
        First: Boolean;
        Second: Boolean;
    begin
        HandlerLog := '';
        Notif.Message('w5 recall false');
        Notif.Send();
        First := Notif.Recall();
        Second := Notif.Recall();
        Observer.Observe('first_recall', Format(First));
        Observer.Observe('second_recall', Format(Second));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Expect('first_recall', 'Yes');
        Observer.Expect('second_recall', 'Yes');
        Observer.Expect('handler_log', 'send;recall(false);recall(false);');
        Observer.Verify();
    end;

    // Send raised, then Recall twice with no recall handler (the send handler is declared because Send surely runs it).
    [Test]
    [HandlerFunctions('SendHandler')]
    procedure Recall_Twice_NoRecallHandler()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
        First: Boolean;
        Second: Boolean;
    begin
        HandlerLog := '';
        Notif.Message('w5 recall no handler');
        Notif.Send();
        First := Notif.Recall();
        Second := Notif.Recall();
        Observer.Observe('first_recall', Format(First));
        Observer.Observe('second_recall', Format(Second));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Expect('first_recall', 'Yes');
        Observer.Expect('second_recall', 'Yes');
        Observer.Expect('handler_log', 'send;');
        Observer.Verify();
    end;

    // Send again after a Recall: the same Id or a new one?
    [Test]
    [HandlerFunctions('SendHandler')]
    procedure Send_Recall_Send_Id()
    var
        Observer: Codeunit "Probe Observer";
        Notif: Notification;
        IdAfterFirstSend: Guid;
        NullGuid: Guid;
    begin
        HandlerLog := '';
        Notif.Message('w5 send recall send');
        Notif.Send();
        IdAfterFirstSend := Notif.Id();
        Notif.Recall();
        Observer.Observe('id_after_recall_same', Format(Notif.Id() = IdAfterFirstSend));
        Notif.Send();
        Observer.Observe('id_after_second_send_same', Format(Notif.Id() = IdAfterFirstSend));
        Observer.Observe('id_not_null', Format(Notif.Id() <> NullGuid));
        Observer.Observe('handler_log', HandlerLog);
        Observer.Expect('id_after_recall_same', 'Yes');
        Observer.Expect('id_after_second_send_same', 'Yes');
        Observer.Expect('id_not_null', 'Yes');
        Observer.Expect('handler_log', 'send;send;');
        Observer.Verify();
    end;
}
