// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/diagnostics/diagnostic-al659
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects 85366-85367
// Facts: corpus issue 670 (odd AL behavior leads, part E): two enums whose names are longer than 30 characters and share the first 30
//   (the compiler gives warning AL0659, no error). The app publishes; Format, Evaluate, AsInteger, Names, Ordinals and FieldRef option strings
//   of each enum are its own.
// Leads: microsoft/AL issues 6740, 6691.
// Probe: values observed on a local BC 29.0 tier; 27.5 and 28.5 checked by the corpus CI.
// BC versions: 27, 28, 29
enum 85366 "LT CV Long Enum Name Shared Prefix One"
{
    Extensible = true;

    value(0; First) { Caption = 'First One'; }
    value(7; Second) { Caption = 'Second One'; }
}

enum 85367 "LT CV Long Enum Name Shared Prefix Two"
{
    Extensible = true;

    value(0; Alpha) { Caption = 'Alpha Two'; }
    value(3; Beta) { Caption = 'Beta Two'; }
    value(4; Gamma) { Caption = 'Gamma Two'; }
}

table 85366 "LT CV Long Enum Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; One; Enum "LT CV Long Enum Name Shared Prefix One") { }
        field(3; Two; Enum "LT CV Long Enum Name Shared Prefix Two") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 85366 "LT CV Enum Long Name Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Join(L: List of [Text]): Text
    var
        T: Text;
        R: Text;
    begin
        foreach T in L do
            R += T + ',';
        exit(R);
    end;

    local procedure JoinInt(L: List of [Integer]): Text
    var
        I: Integer;
        R: Text;
    begin
        foreach I in L do
            R += Format(I) + ',';
        exit(R);
    end;

    [Test]
    procedure EachEnumKeepsItsValues()
    var
        One: Enum "LT CV Long Enum Name Shared Prefix One";
        Two: Enum "LT CV Long Enum Name Shared Prefix Two";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        One := One::Second;
        Two := Two::Beta;
        Observer.Observe('one|format', Format(One));
        Observer.Observe('two|format', Format(Two));
        Observer.Observe('one|int', Format(One.AsInteger()));
        Observer.Observe('two|int', Format(Two.AsInteger()));
        Observer.Observe('one|names', Join(Enum::"LT CV Long Enum Name Shared Prefix One".Names()));
        Observer.Observe('two|names', Join(Enum::"LT CV Long Enum Name Shared Prefix Two".Names()));
        Observer.Observe('one|ordinals', JoinInt(Enum::"LT CV Long Enum Name Shared Prefix One".Ordinals()));
        Observer.Observe('two|ordinals', JoinInt(Enum::"LT CV Long Enum Name Shared Prefix Two".Ordinals()));
        Ok := Evaluate(Two, 'Gamma Two');
        Observer.Observe('two|evaluate', Format(Ok) + '|' + Format(Two.AsInteger()));
        Ok := Evaluate(One, 'Gamma Two');
        Observer.Observe('one|evaluate_other', Format(Ok) + '|' + Format(One.AsInteger()));
        Observer.Expect('one|format', 'Second One');
        Observer.Expect('two|format', 'Beta Two');
        Observer.Expect('one|int', '7');
        Observer.Expect('two|int', '3');
        Observer.Expect('one|names', 'First,Second,');
        Observer.Expect('two|names', 'Alpha,Beta,Gamma,');
        Observer.Expect('one|ordinals', '0,7,');
        Observer.Expect('two|ordinals', '0,3,4,');
        Observer.Expect('two|evaluate', 'Yes|4');
        Observer.Expect('one|evaluate_other', 'No|7');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefOptionStrings()
    var
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        RecRef.Open(Database::"LT CV Long Enum Row");
        Observer.Observe('one|members', RecRef.Field(2).OptionMembers());
        Observer.Observe('two|members', RecRef.Field(3).OptionMembers());
        Observer.Observe('one|captions', RecRef.Field(2).OptionCaption());
        Observer.Observe('two|captions', RecRef.Field(3).OptionCaption());
        Observer.Expect('one|members', 'First,Second');
        Observer.Expect('two|members', 'Alpha,Beta,Gamma');
        Observer.Expect('one|captions', 'First One,Second One');
        Observer.Expect('two|captions', 'Alpha Two,Beta Two,Gamma Two');
        Observer.Verify();
    end;
}
