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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure TestPageSetValueByCaption()
    var
        Row: Record "LT CV Tier Row";
        Card: TestPage "LT CV Tier Card";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Tier.SetValue('Diamond Level, with bonus');
        Observer.Observe('setvalue_caption|value', Card.Tier.Value());
        Card.Tier.SetValue('Silver');
        Card.Tier.SetValue(Enum::"LT CV Tier"::Diamond);
        Observer.Observe('setvalue_enum|value', Card.Tier.Value());
        Card.Tier.SetValue('with bonus');
        Observer.Observe('setvalue_second|value', Card.Tier.Value());
        Card.Close();
        Row.Get(1);
        Observer.Observe('stored', Format(Row.Tier.AsInteger()));
        Observer.Finish();
    end;
}
