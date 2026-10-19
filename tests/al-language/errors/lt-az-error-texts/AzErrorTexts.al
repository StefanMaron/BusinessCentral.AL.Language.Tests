// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80600-80606 below (self-contained)
// Probe: corpus issue 652 (test handlers, dialogs and error texts), items 10, 14 and 15 (items 11 and 13 are pinned in errors/W5ErrorInfoUntouched.al and misc/lt-probes-needed-6/PnF23DecimalToIntegerParam.al), writer AZ.
// BC versions: 27, 28, 29

codeunit 80600 "LT AZ Throw Codeunit"
{
    trigger OnRun()
    begin
        Error('az thrown');
    end;
}

table 80601 "LT AZ Err Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 80602 "LT AZ Err Card"
{
    PageType = Card;
    SourceTable = "LT AZ Err Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(Name; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DbError)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT AZ Err Row";
                begin
                    Row.Get(-77);
                end;
            }
            action(DupInsert)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Row: Record "LT AZ Err Row";
                begin
                    Row.Id := Rec.Id;
                    Row.Insert();
                end;
            }
            action(TestFieldError)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Rec.TestField(Name);
                end;
            }
            action(PlainError)
            {
                ApplicationArea = All;
                trigger OnAction()
                begin
                    Error('az plain');
                end;
            }
        }
    }
}

enum 80605 "LT AZ Color"
{
    Extensible = false;
    value(0; Red) { }
    value(1; Green) { }
}

codeunit 80606 "LT AZ Error Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    // ---- item 10: Codeunit.Run of a codeunit id that does not exist; the raw text (the Observer would scrub the emit version) ----

    [Test]
    procedure CodeunitRun_MissingId_RawText()
    var
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Codeunit.Run(80748);
        Error('RAW ok=%1 code=%2 text=%3', Ok, GetLastErrorCode(), GetLastErrorText());
    end;

    // ---- item 14: GetLastErrorCode after asserterror TestPage action Invoke ----

    [Test]
    procedure PageAction_ErrorCodes()
    var
        Row: Record "LT AZ Err Row";
        Card: TestPage "LT AZ Err Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.DbError.Invoke();
        Observer.ObserveError('get_missing');
        asserterror Card.TestFieldError.Invoke();
        Observer.ObserveError('testfield');
        asserterror Card.PlainError.Invoke();
        Observer.ObserveError('plain');
        Card.Close();
        Observer.Finish();
    end;

    [Test]
    procedure PageAction_DuplicateInsert()
    var
        Row: Record "LT AZ Err Row";
        Card: TestPage "LT AZ Err Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        asserterror Card.DupInsert.Invoke();
        Observer.ObserveError('dup');
        Observer.Finish();
    end;

    // ---- item 15: a Variant holding a non-text value passed to a by-value Text or Code parameter, languages 1036 and 1031 ----

    local procedure TakeText(Value: Text): Text
    begin
        exit('T[' + Value + ']');
    end;

    local procedure TakeCode(Value: Code[20]): Text
    begin
        exit('C[' + Value + ']');
    end;

    [TryFunction]
    local procedure TryText(V: Variant; var R: Text)
    begin
        R := TakeText(V);
    end;

    [TryFunction]
    local procedure TryCode(V: Variant; var R: Text)
    begin
        R := TakeCode(V);
    end;

    local procedure One(V: Variant; Name: Text)
    var
        R: Text;
    begin
        R := '-';
        Observer.Observe(Name + '_text_ok', Format(TryText(V, R)));
        Observer.Observe(Name + '_text_r', R);
        Observer.ObserveError(Name + '_text');
        R := '-';
        Observer.Observe(Name + '_code_ok', Format(TryCode(V, R)));
        Observer.Observe(Name + '_code_r', R);
        Observer.ObserveError(Name + '_code');
    end;

    local procedure ProbeVariants(Lang: Integer; Prefix: Text)
    var
        Color: Enum "LT AZ Color";
        Opt: Option Alpha,Beta;
    begin
        GlobalLanguage(Lang);
        One(12, Prefix + 'int');
        One(1.25, Prefix + 'dec');
        One(true, Prefix + 'bool');
        One(DMY2Date(3, 4, 2024), Prefix + 'date');
        Color := Color::Green;
        One(Color, Prefix + 'enum');
        Opt := Opt::Beta;
        One(Opt, Prefix + 'opt');
        GlobalLanguage(1033);
    end;

    [Test]
    procedure VariantToText_Language1033()
    begin
        ProbeVariants(1033, 'en_');
        Observer.Finish();
    end;

    [Test]
    procedure VariantToText_Language1036()
    begin
        ProbeVariants(1036, 'fr_');
        Observer.Finish();
    end;

    [Test]
    procedure VariantToText_Language1031()
    begin
        ProbeVariants(1031, 'de_');
        Observer.Finish();
    end;
}
