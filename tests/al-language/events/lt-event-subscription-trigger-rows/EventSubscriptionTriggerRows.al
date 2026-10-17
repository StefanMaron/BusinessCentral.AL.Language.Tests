// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 73668, page 73669, publisher 73670, subscribers 73671, test codeunit 73672
// Probe: written against BC; every literal asserted below is what BC produced (BC 27, 28 and 29 by the corpus CI matrix).
// Settles GitHub issue 216 item 1 (NP Retail blockers): rows of the Event Subscription virtual table for subscribers to table trigger events
// (OnBeforeValidateEvent of a field, OnAfterInsertEvent, OnBeforeDeleteEvent), to a page OnAfterActionEvent, and next to them the rows of an
// integration event and a business event subscriber. Every column is read: Event Type, Publisher Object Type and ID, Published Function,
// Active, Number of Calls (before and after the event fired), Error Information, Originating App Name, Subscriber Instance, Active Manual Instances.
// OnAfterValidateEvent of a table or page field and OnOpenPageEvent are pinned in misc/lt-probes-needed-5/PnE11EventSub.al.
// BC versions: 27, 28, 29

table 73668 "LT ESR Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 73669 "LT ESR Card"
{
    PageType = Card;
    SourceTable = "LT ESR Rec";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Name; Rec.Name)
            {
                ApplicationArea = All;
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(DoIt)
            {
                ApplicationArea = All;
                Caption = 'Do It';
            }
        }
    }
}

codeunit 73670 "LT ESR Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnIntegration()
    begin
    end;

    [BusinessEvent(false)]
    procedure OnBusiness()
    begin
    end;

    procedure Raise()
    begin
        OnIntegration();
        OnBusiness();
    end;
}

codeunit 73671 "LT ESR Subs"
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Table, Database::"LT ESR Rec", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure OnTableBeforeValidate(var Rec: Record "LT ESR Rec"; var xRec: Record "LT ESR Rec"; CurrFieldNo: Integer)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT ESR Rec", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnTableAfterInsert(var Rec: Record "LT ESR Rec"; RunTrigger: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT ESR Rec", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnTableBeforeDelete(var Rec: Record "LT ESR Rec"; RunTrigger: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT ESR Card", 'OnAfterActionEvent', 'DoIt', false, false)]
    local procedure OnPageAfterAction(var Rec: Record "LT ESR Rec")
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT ESR Publisher", 'OnIntegration', '', false, false)]
    local procedure OnIntegrationSub()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT ESR Publisher", 'OnBusiness', '', false, false)]
    local procedure OnBusinessSub()
    begin
    end;
}

codeunit 73672 "LT ESR Event Sub Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(SubscriberFunction: Text; SkipCalls: Boolean; var Count: Integer; var Calls: Integer): Text
    var
        Sub: Record "Event Subscription";
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        R: Text;
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT ESR Subs");
        Sub.SetRange("Subscriber Function", SubscriberFunction);
        Count := Sub.Count();
        Calls := -1;
        if not Sub.FindFirst() then
            exit('');
        Calls := Sub."Number of Calls";
        RR.GetTable(Sub);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if not (SkipCalls and (FR.Name = 'Number of Calls')) then
                R += FR.Name + '=' + Format(FR.Value) + ';';
        end;
        exit(R);
    end;

    local procedure Calls(SubscriberFunction: Text): Integer
    var
        Count: Integer;
        N: Integer;
    begin
        Dump(SubscriberFunction, true, Count, N);
        exit(N);
    end;

    [Test]
    procedure EventSubscription_TableBeforeValidateRow()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ESR Rec";
        Count: Integer;
        N: Integer;
        Before: Integer;
    begin
        Before := Calls('OnTableBeforeValidate');
        Rec.Init();
        Rec.Validate(Name, 'x');
        Observer.Observe('callsDelta', Format(Calls('OnTableBeforeValidate') - Before));
        Observer.Observe('row', Dump('OnTableBeforeValidate', true, Count, N));
        Observer.Observe('count', Format(Count));
        Observer.Finish();
    end;

    [Test]
    procedure EventSubscription_TableAfterInsertRow()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ESR Rec";
        Count: Integer;
        N: Integer;
        Before: Integer;
    begin
        Rec.DeleteAll();
        Before := Calls('OnTableAfterInsert');
        Rec.Id := 1;
        Rec.Insert(true);
        Observer.Observe('callsDelta', Format(Calls('OnTableAfterInsert') - Before));
        Observer.Observe('row', Dump('OnTableAfterInsert', true, Count, N));
        Observer.Observe('count', Format(Count));
        Observer.Finish();
    end;

    [Test]
    procedure EventSubscription_TableBeforeDeleteRow()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ESR Rec";
        Count: Integer;
        N: Integer;
        Before: Integer;
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Before := Calls('OnTableBeforeDelete');
        Rec.Delete(true);
        Observer.Observe('callsDelta', Format(Calls('OnTableBeforeDelete') - Before));
        Observer.Observe('row', Dump('OnTableBeforeDelete', true, Count, N));
        Observer.Observe('count', Format(Count));
        Observer.Finish();
    end;

    [Test]
    procedure EventSubscription_PageAfterActionRow()
    var
        Observer: Codeunit "Probe Observer";
        Count: Integer;
        N: Integer;
    begin
        Observer.Observe('row', Dump('OnPageAfterAction', false, Count, N));
        Observer.Observe('count', Format(Count));
        Observer.Finish();
    end;

    [Test]
    procedure EventSubscription_IntegrationAndBusinessEventRows()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "LT ESR Publisher";
        Count: Integer;
        N: Integer;
        BeforeI: Integer;
        BeforeB: Integer;
    begin
        BeforeI := Calls('OnIntegrationSub');
        BeforeB := Calls('OnBusinessSub');
        Publisher.Raise();
        Observer.Observe('integrationCallsDelta', Format(Calls('OnIntegrationSub') - BeforeI));
        Observer.Observe('businessCallsDelta', Format(Calls('OnBusinessSub') - BeforeB));
        Observer.Observe('integrationRow', Dump('OnIntegrationSub', true, Count, N));
        Observer.Observe('integrationCount', Format(Count));
        Observer.Observe('businessRow', Dump('OnBusinessSub', true, Count, N));
        Observer.Observe('businessCount', Format(Count));
        Observer.Finish();
    end;

    [Test]
    procedure EventSubscription_FilterByPublisherKindAndFunction()
    var
        Observer: Codeunit "Probe Observer";
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"LT ESR Subs");
        Observer.Observe('all', Format(Sub.Count()));
        Sub.SetRange("Event Type", Sub."Event Type"::"Trigger");
        Observer.Observe('trigger', Format(Sub.Count()));
        Sub.SetRange("Event Type", Sub."Event Type"::Integration);
        Observer.Observe('integration', Format(Sub.Count()));
        Sub.SetRange("Event Type", Sub."Event Type"::Business);
        Observer.Observe('business', Format(Sub.Count()));
        Sub.SetRange("Event Type");
        Sub.SetRange("Publisher Object Type", Sub."Publisher Object Type"::Table);
        Observer.Observe('tablePublisher', Format(Sub.Count()));
        Sub.SetRange("Publisher Object Type", Sub."Publisher Object Type"::Page);
        Observer.Observe('pagePublisher', Format(Sub.Count()));
        Sub.SetRange("Publisher Object Type", Sub."Publisher Object Type"::Codeunit);
        Observer.Observe('codeunitPublisher', Format(Sub.Count()));
        Sub.SetRange("Publisher Object Type");
        Sub.SetRange("Published Function", 'OnAfterInsertEvent');
        Observer.Observe('afterInsertByName', Format(Sub.Count()));
        Sub.SetRange("Published Function", 'OnBeforeValidateEvent - Name');
        Observer.Observe('beforeValidateByName', Format(Sub.Count()));
        Sub.SetRange("Published Function", 'OnAfterActionEvent - DoIt');
        Observer.Observe('afterActionByName', Format(Sub.Count()));
        Observer.Finish();
    end;
}
