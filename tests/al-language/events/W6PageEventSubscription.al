// Batch 6, md:970 [Event Subscription row of a page control validate event]: the row of the Event Subscription virtual table for a subscriber to
// ObjectType::Page, Page::X, 'OnAfterValidateEvent', '<control name>': "Published Function", "Event Type", publisher columns, "Active", "Number of Calls" before and
// after the event fired through a TestPage. The table form (OnAfterValidateEvent on a table field) is read next to it for comparison.
// A subscriber to a page element that is NOT a control name does not compile (AL0270: "The control 'Name' is not found in the target"): the element is the CONTROL name.
// Observe-only.

table 67335 "W6 ES Table"
{
    DataClassification = SystemMetadata;

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

page 67336 "W6 ES Card"
{
    PageType = Card;
    SourceTable = "W6 ES Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name) { ApplicationArea = All; }
        }
    }
}

codeunit 67337 "W6 ES Subscribers"
{
    [EventSubscriber(ObjectType::Page, Page::"W6 ES Card", 'OnAfterValidateEvent', 'NameCtl', false, false)]
    local procedure PageControlValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Page, Page::"W6 ES Card", 'OnAfterValidateEvent', 'Id', false, false)]
    local procedure PageSameNameControlValidate()
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"W6 ES Table", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure TableFieldValidate()
    begin
    end;
}

codeunit 67338 "W6 Page Event Subscription"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveRow(SubscriberFunction: Text; Prefix: Text; var Observer: Codeunit "Probe Observer")
    var
        Sub: Record "Event Subscription";
    begin
        Sub.SetRange("Subscriber Codeunit ID", Codeunit::"W6 ES Subscribers");
        Sub.SetRange("Subscriber Function", SubscriberFunction);
        Observer.Observe(Prefix + '_row_count', Format(Sub.Count()));
        if not Sub.FindFirst() then
            exit;
        Observer.Observe(Prefix + '_published_function', Sub."Published Function");
        Observer.Observe(Prefix + '_event_type', Format(Sub."Event Type"));
        Observer.Observe(Prefix + '_event_type_ordinal', Format(Sub."Event Type", 0, 2));
        Observer.Observe(Prefix + '_publisher_object_type', Format(Sub."Publisher Object Type"));
        Observer.Observe(Prefix + '_publisher_object_id_is_the_publisher', Format((Sub."Publisher Object ID" = Page::"W6 ES Card") or (Sub."Publisher Object ID" = Database::"W6 ES Table")));
        Observer.Observe(Prefix + '_active', Format(Sub.Active));
        Observer.Observe(Prefix + '_number_of_calls', Format(Sub."Number of Calls"));
    end;

    [Test]
    procedure Row_TableFieldValidate_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRow('TableFieldValidate', 'table_field', Observer);
        Observer.Expect('table_field_row_count', '1');
        Observer.Expect('table_field_published_function', 'OnAfterValidateEvent - Name');
        Observer.Expect('table_field_event_type', 'Trigger');
        Observer.Expect('table_field_event_type_ordinal', '0');
        Observer.Expect('table_field_publisher_object_type', 'Table');
        Observer.Expect('table_field_publisher_object_id_is_the_publisher', 'Yes');
        Observer.Expect('table_field_active', 'Yes');
        Observer.Expect('table_field_number_of_calls', '0');
        Observer.Verify();
    end;

}
