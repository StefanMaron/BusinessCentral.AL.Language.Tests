// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85365
// Facts: corpus issue 670 (odd AL behavior leads, part E): an enum value whose Caption contains a comma ('Diamond Level, with bonus'):
//   Format, Evaluate from the caption and from the name, FieldRef.OptionCaption and OptionMembers of a field of that enum, and
//   TestPage SetValue by caption (Learn warns that a comma in a caption can select the wrong value).
// BC versions: 27, 28, 29
enum 85365 "LT CV Tier"
{
    Extensible = true;

    value(0; Plain) { Caption = 'Plain'; }
    value(1; Diamond) { Caption = 'Diamond Level, with bonus'; }
    value(2; Gold) { Caption = 'with bonus'; }
    value(3; Silver) { Caption = 'Silver'; }
}

table 85365 "LT CV Tier Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Tier; Enum "LT CV Tier") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 85365 "LT CV Tier Card"
{
    PageType = Card;
    SourceTable = "LT CV Tier Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Tier; Rec.Tier) { ApplicationArea = All; }
        }
    }
}

codeunit 85365 "LT CV Enum Caption Comma Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TryEvaluate(Txt: Text): Text
    var
        E: Enum "LT CV Tier";
        Ok: Boolean;
    begin
        E := E::Silver;
        Ok := Evaluate(E, Txt);
        exit(Format(Ok) + '|' + Format(E.AsInteger()));
    end;

    [Test]
    procedure FormatAndEvaluate()
    var
        E: Enum "LT CV Tier";
        Observer: Codeunit "Probe Observer";
    begin
        E := E::Diamond;
        Observer.Observe('format', Format(E));
        Observer.Observe('format_9', Format(E, 0, 9));
        Observer.Observe('format_2', Format(E, 0, 2));
        Observer.Observe('names', Enum::"LT CV Tier".Names().Get(2));
        Observer.Observe('eval|caption', TryEvaluate('Diamond Level, with bonus'));
        Observer.Observe('eval|name', TryEvaluate('Diamond'));
        Observer.Observe('eval|second_half', TryEvaluate('with bonus'));
        Observer.Observe('eval|first_half', TryEvaluate('Diamond Level'));
        Observer.Expect('format', 'Diamond Level, with bonus');
        Observer.Expect('format_9', '1');
        Observer.Expect('format_2', '1');
        Observer.Expect('names', 'Diamond');
        Observer.Expect('eval|caption', 'Yes|1');
        Observer.Expect('eval|name', 'Yes|1');
        Observer.Expect('eval|second_half', 'Yes|2');
        Observer.Expect('eval|first_half', 'No|3');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefOptionStrings()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"LT CV Tier Row");
        FldRef := RecRef.Field(2);
        Observer.Observe('optioncaption', FldRef.OptionCaption());
        Observer.Observe('optionmembers', FldRef.OptionMembers());
        FldRef.Value := Enum::"LT CV Tier"::Diamond;
        Observer.Observe('fieldref_format', Format(FldRef.Value));
        Observer.Expect('optioncaption', 'Plain,Diamond Level, with bonus,with bonus,Silver');
        Observer.Expect('optionmembers', 'Plain,Diamond,Gold,Silver');
        Observer.Expect('fieldref_format', 'Diamond Level, with bonus');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySetValue(var Card: TestPage "LT CV Tier Card"; NewValue: Text)
    begin
        Card.Tier.SetValue(NewValue);
    end;

    local procedure SetOnFreshPage(var Observer: Codeunit "Probe Observer"; Name: Text; NewValue: Text)
    var
        Row: Record "LT CV Tier Row";
        Card: TestPage "LT CV Tier Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Tier := Row.Tier::Silver;
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        ClearLastError();
        Observer.Observe(Name + '|ok', Format(TrySetValue(Card, NewValue)));
        Observer.ObserveError(Name);
        Observer.Observe(Name + '|value', Card.Tier.Value());
        Card.Close();
        Row.Get(1);
        Observer.Observe(Name + '|stored', Format(Row.Tier.AsInteger()));
    end;

    [Test]
    procedure TestPageSetValueByCaption()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SetOnFreshPage(Observer, 'caption_with_comma', 'Diamond Level, with bonus');
        SetOnFreshPage(Observer, 'second_half', 'with bonus');
        SetOnFreshPage(Observer, 'first_half', 'Diamond Level');
        SetOnFreshPage(Observer, 'name', 'Diamond');
        SetOnFreshPage(Observer, 'plain_caption', 'Plain');
        Observer.Finish();
    end;
}
