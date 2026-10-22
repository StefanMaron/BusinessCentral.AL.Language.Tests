// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-triggers
// Scope: in-scope
// Fixtures used: ISO Event Row (67100), ISO Event Publisher (67101), ISO Event Subscribers (67102),
//                shared Assert (60021); self-contained tables 68151, 68153 and codeunits 68150, 68152,
//                68154..68157
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the order and arguments of the table events around each trigger: Before event, trigger,
// After event, with the RunTrigger value each carries (Insert(false), Modify(false), Delete(false),
// DeleteAll and ModifyAll, with and without triggers), the xRec handle shared by subscribers and the
// trigger, Validate events and their CurrFieldNo, events on temporary records, which events run before
// an error, the order of several subscribers (ascending codeunit id, not name or declaration), and
// how BindSubscription and an isolated event report errors.
// BC versions: 27.5

codeunit 68150 "Probe Ev Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

table 68151 "Probe Evt"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Text[20])
        {
            trigger OnValidate()
            var
                EvLog: Codeunit "Probe Ev Log";
            begin
                EvLog.Add('Val.OnValidate(rec=' + Val + ',x=' + xRec.Val + ')');
            end;
        }
        field(3; Num; Integer) { }
        field(4; Pay; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('T.OnInsert(rec=' + Val + ')');
    end;

    trigger OnModify()
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('T.OnModify(rec=' + Val + ',x=' + xRec.Val + ')');
    end;

    trigger OnDelete()
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('T.OnDelete(' + Format(Id) + ')');
    end;

    trigger OnRename()
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('T.OnRename(rec=' + Format(Id) + ',x=' + Format(xRec.Id) + ')');
    end;
}

codeunit 68152 "Probe Evt Sub"
{
    var
        Hits: Integer;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        Hits += 1;
        EvLog.Add('S.BeforeInsert(run=' + Format(RunTrigger) + ',temp=' + Format(Rec.IsTemporary()) + ',hits=' + Format(Hits) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnAfterInsertEvent', '', false, false)]
    local procedure AfterInsert(var Rec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.AfterInsert(run=' + Format(RunTrigger) + ',hits=' + Format(Hits) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "Probe Evt"; var xRec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.BeforeModify(run=' + Format(RunTrigger) + ',rec=' + Rec.Val + ',x=' + xRec.Val + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "Probe Evt"; var xRec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.AfterModify(run=' + Format(RunTrigger) + ',rec=' + Rec.Val + ',x=' + xRec.Val + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDelete(var Rec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.BeforeDelete(run=' + Format(RunTrigger) + ',' + Format(Rec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDelete(var Rec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.AfterDelete(run=' + Format(RunTrigger) + ',' + Format(Rec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnBeforeRenameEvent', '', false, false)]
    local procedure BeforeRename(var Rec: Record "Probe Evt"; var xRec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.BeforeRename(run=' + Format(RunTrigger) + ',rec=' + Format(Rec.Id) + ',x=' + Format(xRec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnAfterRenameEvent', '', false, false)]
    local procedure AfterRename(var Rec: Record "Probe Evt"; var xRec: Record "Probe Evt"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.AfterRename(run=' + Format(RunTrigger) + ',rec=' + Format(Rec.Id) + ',x=' + Format(xRec.Id) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnBeforeValidateEvent', 'Val', false, false)]
    local procedure BeforeValidate(var Rec: Record "Probe Evt"; var xRec: Record "Probe Evt"; CurrFieldNo: Integer)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.BeforeValidate(rec=' + Rec.Val + ',x=' + xRec.Val + ',cur=' + Format(CurrFieldNo) + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt", 'OnAfterValidateEvent', 'Val', false, false)]
    local procedure AfterValidate(var Rec: Record "Probe Evt"; var xRec: Record "Probe Evt"; CurrFieldNo: Integer)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('S.AfterValidate(rec=' + Rec.Val + ',x=' + xRec.Val + ',cur=' + Format(CurrFieldNo) + ')');
    end;
}

table 68153 "Probe Evt2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Text[20]) { }
        field(3; Pay; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnModify()
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('T.OnModify(rec=' + Val + ',x=' + xRec.Val + ')');
    end;

    trigger OnInsert()
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('T.OnInsert(rec=' + Val + ')');
        if Val = 'boom' then
            Error('trigger error');
    end;
}

// Declared first, higher id, name sorts first: the order of the subscribers below shows which of
// the three the platform follows.
codeunit 68156 "Probe Ev A High"
{
    [EventSubscriber(ObjectType::Table, Database::"Probe Evt2", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "Probe Evt2"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('High.BeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt2", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "Probe Evt2"; var xRec: Record "Probe Evt2"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('High.BeforeModify(x=' + xRec.Val + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt2", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "Probe Evt2"; var xRec: Record "Probe Evt2"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('High.AfterModify(x=' + xRec.Val + ')');
    end;
}

codeunit 68154 "Probe Ev Z Low"
{
    [EventSubscriber(ObjectType::Table, Database::"Probe Evt2", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "Probe Evt2"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('Low.BeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt2", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "Probe Evt2"; var xRec: Record "Probe Evt2"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('Low.BeforeModify(x=' + xRec.Val + ')');
        xRec.Val := 'CHANGED-BY-LOW';
    end;
}

codeunit 68155 "Probe Ev Manual"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"Probe Evt2", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "Probe Evt2"; RunTrigger: Boolean)
    var
        EvLog: Codeunit "Probe Ev Log";
    begin
        EvLog.Add('Manual.BeforeInsert');
    end;
}

codeunit 68157 "Probe Table Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EvLog: Codeunit "Probe Ev Log";

    local procedure Initialize()
    var
        Evt: Record "Probe Evt";
        Evt2: Record "Probe Evt2";
    begin
        Evt.DeleteAll();
        Evt2.DeleteAll();
        Commit();
        EvLog.Take();
    end;

    [Test]
    procedure Insert_EventsAndTrigger_WithAndWithoutRunTrigger()
    var
        Evt: Record "Probe Evt";
    begin
        Initialize();

        Evt.Id := 1;
        Evt.Val := 'a';
        Evt.Insert(true);
        Assert.AreEqual('S.BeforeInsert(run=Yes,temp=No,hits=1);T.OnInsert(rec=a);S.AfterInsert(run=Yes,hits=0);', EvLog.Take(),
            'Insert(true): the After event sees a fresh subscriber instance (hits=0)');

        Evt.Id := 2;
        Evt.Insert(false);
        Assert.AreEqual('S.BeforeInsert(run=No,temp=No,hits=1);S.AfterInsert(run=No,hits=0);', EvLog.Take(), 'Insert(false): events fire, the trigger does not');
    end;

    [Test]
    procedure ModifyRenameDelete_EventsAndTrigger()
    var
        Evt: Record "Probe Evt";
    begin
        Initialize();
        Evt.Id := 1;
        Evt.Val := 'a';
        Evt.Insert(false);
        Evt.Id := 2;
        Evt.Insert(false);
        EvLog.Take();

        Evt.Get(1);
        Evt.Val := 'a2';
        Evt.Modify(true);
        Assert.AreEqual('S.BeforeModify(run=Yes,rec=a2,x=a2);T.OnModify(rec=a2,x=a2);S.AfterModify(run=Yes,rec=a2,x=a2);', EvLog.Take(),
            'Modify(true): in code, xRec holds the same values as Rec');

        Evt.Val := 'a3';
        Evt.Modify(false);
        Assert.AreEqual('S.BeforeModify(run=No,rec=a3,x=a3);S.AfterModify(run=No,rec=a3,x=a3);', EvLog.Take(), 'Modify(false)');

        Evt.Rename(10);
        Assert.AreEqual('S.BeforeRename(run=Yes,rec=10,x=1);T.OnRename(rec=10,x=1);S.AfterRename(run=Yes,rec=10,x=1);', EvLog.Take(), 'Rename always runs the trigger');

        Evt.Delete(true);
        Assert.AreEqual('S.BeforeDelete(run=Yes,10);T.OnDelete(10);S.AfterDelete(run=Yes,10);', EvLog.Take(), 'Delete(true)');

        Evt.Get(2);
        Evt.Delete(false);
        Assert.AreEqual('S.BeforeDelete(run=No,2);S.AfterDelete(run=No,2);', EvLog.Take(), 'Delete(false)');
    end;

    [Test]
    procedure DeleteAllAndModifyAll_RaiseTheEventsOncePerRow()
    var
        Evt: Record "Probe Evt";
        Rows: Record "Probe Evt";
    begin
        Initialize();
        Evt.Id := 3;
        Evt.Insert(false);
        Evt.Id := 4;
        Evt.Insert(false);
        EvLog.Take();

        Rows.DeleteAll(true);
        Assert.AreEqual('S.BeforeDelete(run=Yes,3);T.OnDelete(3);S.AfterDelete(run=Yes,3);S.BeforeDelete(run=Yes,4);T.OnDelete(4);S.AfterDelete(run=Yes,4);', EvLog.Take(), 'DeleteAll(true)');

        Evt.Id := 3;
        Evt.Insert(false);
        Evt.Id := 4;
        Evt.Insert(false);
        EvLog.Take();
        Rows.DeleteAll(false);
        Assert.AreEqual('S.BeforeDelete(run=No,3);S.AfterDelete(run=No,3);S.BeforeDelete(run=No,4);S.AfterDelete(run=No,4);', EvLog.Take(), 'DeleteAll(false): events fire per row');

        Evt.Id := 5;
        Evt.Val := 'x';
        Evt.Insert(false);
        Evt.Id := 6;
        Evt.Insert(false);
        EvLog.Take();
        Rows.ModifyAll(Val, 'm', true);
        Assert.AreEqual('S.BeforeModify(run=Yes,rec=m,x=m);T.OnModify(rec=m,x=m);S.AfterModify(run=Yes,rec=m,x=m);S.BeforeModify(run=Yes,rec=m,x=m);T.OnModify(rec=m,x=m);S.AfterModify(run=Yes,rec=m,x=m);', EvLog.Take(), 'ModifyAll(true)');

        Rows.ModifyAll(Val, 'n', false);
        Assert.AreEqual('S.BeforeModify(run=No,rec=n,x=n);S.AfterModify(run=No,rec=n,x=n);S.BeforeModify(run=No,rec=n,x=n);S.AfterModify(run=No,rec=n,x=n);', EvLog.Take(), 'ModifyAll(false)');

        Rows.ModifyAll(Num, 7);
        Assert.AreEqual('S.BeforeModify(run=No,rec=n,x=n);S.AfterModify(run=No,rec=n,x=n);S.BeforeModify(run=No,rec=n,x=n);S.AfterModify(run=No,rec=n,x=n);', EvLog.Take(), 'ModifyAll without the RunTrigger argument runs no trigger');
    end;

    [Test]
    procedure Validate_Events_SeeTheNewValueInRec_TheOldInXRec_AndCurrFieldNoZero()
    var
        Evt: Record "Probe Evt";
    begin
        Initialize();
        Evt.Id := 1;
        Evt.Val := 'old';

        Evt.Validate(Val, 'new');

        Assert.AreEqual('S.BeforeValidate(rec=new,x=old,cur=0);Val.OnValidate(rec=new,x=old);S.AfterValidate(rec=new,x=old,cur=0);', EvLog.Take(), 'Validate with a value');

        Evt.Val := 'old2';
        Evt.Validate(Val);
        Assert.AreEqual('S.BeforeValidate(rec=old2,x=old2,cur=0);Val.OnValidate(rec=old2,x=old2);S.AfterValidate(rec=old2,x=old2,cur=0);', EvLog.Take(), 'Validate without a value');
    end;

    [Test]
    procedure TemporaryRecord_RaisesTheEventsAndRunsTheTriggers()
    var
        Evt: Record "Probe Evt" temporary;
    begin
        Initialize();

        Evt.Id := 1;
        Evt.Val := 'a';
        Evt.Insert(true);
        Assert.AreEqual('S.BeforeInsert(run=Yes,temp=Yes,hits=1);T.OnInsert(rec=a);S.AfterInsert(run=Yes,hits=0);', EvLog.Take(), 'Insert');

        Evt.Val := 'b';
        Evt.Modify(true);
        Assert.AreEqual('S.BeforeModify(run=Yes,rec=b,x=b);T.OnModify(rec=b,x=b);S.AfterModify(run=Yes,rec=b,x=b);', EvLog.Take(), 'Modify');

        Evt.Delete(true);
        Assert.AreEqual('S.BeforeDelete(run=Yes,1);T.OnDelete(1);S.AfterDelete(run=Yes,1);', EvLog.Take(), 'Delete');
    end;

    [Test]
    procedure FailingWrites_RaiseTheBeforeEventAndTheTrigger_ThenTheError()
    // CLAIM: for a duplicate Insert, and a Modify, Delete or Rename of a missing row, the Before event and the trigger run first; the After event does not.
    var
        Evt: Record "Probe Evt";
    begin
        Initialize();
        Evt.Id := 1;
        Evt.Val := 'a';
        Evt.Insert(true);
        Commit();
        EvLog.Take();

        Evt.Id := 1;
        asserterror Evt.Insert(true);
        Assert.AreEqual('S.BeforeInsert(run=Yes,temp=No,hits=1);T.OnInsert(rec=a);', EvLog.Take(), 'duplicate Insert');

        Evt.Id := 99;
        Evt.Val := 'x';
        asserterror Evt.Modify(true);
        Assert.AreEqual('S.BeforeModify(run=Yes,rec=x,x=x);T.OnModify(rec=x,x=x);', EvLog.Take(), 'Modify of a missing row');

        asserterror Evt.Delete(true);
        Assert.AreEqual('S.BeforeDelete(run=Yes,99);T.OnDelete(99);', EvLog.Take(), 'Delete of a missing row');

        asserterror Evt.Rename(100);
        Assert.AreEqual('S.BeforeRename(run=Yes,rec=100,x=99);T.OnRename(rec=100,x=99);', EvLog.Take(), 'Rename of a missing row');
    end;

    [Test]
    procedure Subscribers_RunInAscendingCodeunitIdOrder_AndShareTheXRecHandle()
    // CLAIM: "Probe Ev Z Low" (68154) runs before "Probe Ev A High" (68156) although it is declared later and sorts later by name; a change to xRec made by the first is seen by the second, the trigger and the After event.
    var
        Evt2: Record "Probe Evt2";
    begin
        Initialize();
        Evt2.Id := 1;
        Evt2.Val := 'a';

        Evt2.Insert(true);
        Assert.AreEqual('Low.BeforeInsert;High.BeforeInsert;T.OnInsert(rec=a);', EvLog.Take(), 'Insert');

        Evt2.Get(1);
        Evt2.Val := 'b';
        Evt2.Modify(true);
        Assert.AreEqual('Low.BeforeModify(x=b);High.BeforeModify(x=CHANGED-BY-LOW);T.OnModify(rec=b,x=CHANGED-BY-LOW);High.AfterModify(x=CHANGED-BY-LOW);', EvLog.Take(), 'Modify');
    end;

    [Test]
    procedure BindSubscription_Manual_Twice_And_Static_Errors()
    var
        Evt2: Record "Probe Evt2";
        Manual: Codeunit "Probe Ev Manual";
        Static: Codeunit "Probe Ev Z Low";
        Bound: Boolean;
    begin
        Initialize();

        BindSubscription(Manual);
        Evt2.Id := 1;
        Evt2.Insert(true);
        Assert.AreEqual('Low.BeforeInsert;Manual.BeforeInsert;High.BeforeInsert;T.OnInsert(rec=);', EvLog.Take(), 'a bound manual subscriber takes its place in the codeunit id order (68154, 68155, 68156)');

        asserterror BindSubscription(Manual);
        Assert.AreEqual('The binding of codeunit 68155 was unsuccessful. The codeunit has already been bound.', GetLastErrorText(), 'bound twice');
        Assert.AreEqual('EventBinding', GetLastErrorCode(), 'code');

        Assert.IsTrue(UnbindSubscription(Manual), 'unbind');
        Evt2.Id := 2;
        Evt2.Insert(true);
        Assert.AreEqual('Low.BeforeInsert;High.BeforeInsert;T.OnInsert(rec=);', EvLog.Take(), 'after Unbind');

        asserterror BindSubscription(Static);
        Assert.AreEqual('The binding of codeunit 68154 was unsuccessful. The codeunit does not use manual binding', GetLastErrorText(), 'a codeunit that does not use manual binding (no full stop)');
        Assert.AreEqual('EventBinding', GetLastErrorCode(), 'code');

        Bound := BindSubscription(Static);
        Assert.IsFalse(Bound, 'the Boolean form returns false');
        Assert.IsFalse(UnbindSubscription(Static), 'UnbindSubscription of a codeunit that does not use manual binding returns false');
    end;

    [Test]
    procedure TriggerError_PropagatesWithCodeDialog()
    var
        Evt2: Record "Probe Evt2";
    begin
        Initialize();
        Evt2.Id := 1;
        Evt2.Val := 'boom';

        asserterror Evt2.Insert(true);

        Assert.AreEqual('Low.BeforeInsert;High.BeforeInsert;T.OnInsert(rec=boom);', EvLog.Take(), 'sequence before the error');
        Assert.AreEqual('trigger error', GetLastErrorText(), 'text');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure IsolatedEvent_SubscriberError_BecomesTheLastError_AndTheOtherSubscribersWriteIsCommitted()
    var
        Publisher: Codeunit "ISO Event Publisher";
        Row: Record "ISO Event Row";
    begin
        Initialize();
        Row.DeleteAll();
        Commit();
        ClearLastError();

        Publisher.RaiseIsolated();

        Assert.AreEqual('ISO-SUBSCRIBER-FAILED', GetLastErrorText(), 'the swallowed error is the last error');
        Assert.AreEqual('Dialog', GetLastErrorCode(), 'code');
        Assert.AreEqual(1, Row.Count(), 'the succeeding subscriber wrote its row');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'and its transaction was committed');

        Row.DeleteAll();
        Commit();
    end;
}
