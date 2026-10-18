// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80600-80609 below (self-contained)
// Probe: corpus issue 652 (test handlers, dialogs and error texts), items 10, 11, 13, 14 and 15, writer AZ.
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
            action(PermError)
            {
                ApplicationArea = All;
                trigger OnAction()
                var
                    Lic: Record "License Information";
                begin
                    Lic.Init();
                    Lic.Insert();
                end;
            }
        }
    }
}

page 80603 "LT AZ Overload Card"
{
    PageType = Card;
    SourceTable = "LT AZ Err Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
        }
    }
}

pageextension 80604 "LT AZ Overload Ext" extends "LT AZ Overload Card"
{
    procedure Pick(Value: Integer): Text
    begin
        exit('int:' + Format(Value));
    end;

    procedure Pick(Value: Text): Text
    begin
        exit('text:' + Value);
    end;

    procedure Pick(Value: Boolean): Text
    begin
        exit('bool:' + Format(Value));
    end;
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

    // ---- item 11: an ErrorInfo never created with ErrorInfo.Create ----

    [Test]
    procedure ErrorInfo_NotCreated_Defaults()
    var
        EI: ErrorInfo;
    begin
        Observer.Observe('collectible', Format(EI.Collectible));
        Observer.Observe('verbosity', Format(EI.Verbosity));
        Observer.Observe('errortype', Format(EI.ErrorType));
        Observer.Observe('dataclassification', Format(EI.DataClassification));
        Observer.Observe('message', EI.Message);
        Observer.Observe('title', EI.Title);
        Observer.Observe('detailed', EI.DetailedMessage);
        Observer.Observe('tableid', Format(EI.TableId));
        Observer.Observe('fieldno', Format(EI.FieldNo));
        Observer.Observe('systemid', Format(EI.SystemId));
        asserterror Error(EI);
        Observer.ObserveError('raise_empty');
        EI.Message := 'az set';
        Observer.Observe('message_after', EI.Message);
        Observer.Observe('collectible_after', Format(EI.Collectible));
        Observer.Observe('errortype_after', Format(EI.ErrorType));
        asserterror Error(EI);
        Observer.ObserveError('raise_set');
        Observer.Finish();
    end;

    // ---- item 13: a non-integral Decimal passed to an Integer parameter, assigned to an Integer ----

    local procedure TakeInt(Value: Integer): Integer
    begin
        exit(Value);
    end;

    [TryFunction]
    local procedure TryTakeInt(D: Decimal; var Got: Integer)
    begin
        Got := TakeInt(D);
    end;

    [TryFunction]
    local procedure TryAssign(D: Decimal; var Got: Integer)
    begin
        Got := D;
    end;

    [TryFunction]
    local procedure TryTakeLiteral(var Got: Integer)
    begin
        Got := TakeInt(1.5);
    end;

    [TryFunction]
    local procedure TryTakeVariant(V: Variant; var Got: Integer)
    begin
        Got := TakeInt(V);
    end;

    [TryFunction]
    local procedure TryPick(var Card: Page "LT AZ Overload Card"; D: Decimal; var Got: Text)
    begin
        Got := Card.Pick(D);
    end;

    [Test]
    procedure DecimalToInteger_ParameterAndAssignment()
    var
        D: Decimal;
        I: Integer;
        V: Variant;
    begin
        D := 1.5;
        I := -1;
        Observer.Observe('try_param', Format(TryTakeInt(D, I)));
        Observer.Observe('param_I', Format(I));
        Observer.ObserveError('param');
        I := -1;
        Observer.Observe('try_assign', Format(TryAssign(D, I)));
        Observer.Observe('assign_I', Format(I));
        Observer.ObserveError('assign');
        D := 2.5;
        I := -1;
        Observer.Observe('try_assign25', Format(TryAssign(D, I)));
        Observer.Observe('assign25_I', Format(I));
        Observer.ObserveError('assign25');
        D := -1.5;
        I := -1;
        Observer.Observe('try_assignm15', Format(TryAssign(D, I)));
        Observer.Observe('assignm15_I', Format(I));
        Observer.ObserveError('assignm15');
        D := 3;
        I := -1;
        Observer.Observe('try_assign3', Format(TryAssign(D, I)));
        Observer.Observe('assign3_I', Format(I));
        I := -1;
        Observer.Observe('try_literal', Format(TryTakeLiteral(I)));
        Observer.Observe('literal_I', Format(I));
        Observer.ObserveError('literal_param');
        V := 1.5;
        I := -1;
        Observer.Observe('try_variant', Format(TryTakeVariant(V, I)));
        Observer.Observe('variant_I', Format(I));
        Observer.ObserveError('variant_param');
        Observer.Finish();
    end;

    [Test]
    procedure DecimalToInteger_PageExtensionOverload()
    var
        Card: Page "LT AZ Overload Card";
        D: Decimal;
        T: Text;
    begin
        D := 1.5;
        T := '-';
        Observer.Observe('try_dec_var', Format(TryPick(Card, D, T)));
        Observer.Observe('dec_var_T', T);
        Observer.ObserveError('dec_var');
        Observer.Observe('pick_int', Card.Pick(7));
        Observer.Observe('pick_text', Card.Pick('a'));
        Observer.Observe('pick_bool', Card.Pick(true));
        D := 4;
        Observer.Observe('pick_dec4', Card.Pick(D));
        Observer.Finish();
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

    [Test]
    procedure PageAction_PermissionError()
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
        asserterror Card.PermError.Invoke();
        Observer.ObserveError('perm');
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
