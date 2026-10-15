// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-testfield-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// Record.TestField(Field, ErrorInfo) and TestField(Field, Value, ErrorInfo): a passing check raises nothing and leaves the ErrorInfo as it was. A failing check raises the SAME text and code
// (TestField) as the form without ErrorInfo, whatever Message the ErrorInfo carries (a custom message is NOT used): "<Field> must have a value in <Table>: <Key>. It cannot be zero
// or empty." for a blank Text or Decimal, "<Field> must not be Zero in <Table>: <Key>" for an Option at its zero member, "<Field> must be equal to '<value>'  in <Table>: <Key>. Current
// value is '<actual>'." for a wrong value (two spaces before "in"). In an ErrorBehavior::Collect scope with a COLLECTIBLE ErrorInfo each failing call is collected instead of raising
// (3 collected errors for three failing calls), with the ErrorInfo's Message, ErrorType Client, FieldNo of the tested field and the TableId. A non collectible ErrorInfo outside a collect
// scope raises the standard error and keeps FieldNo 0 and TableId 0 on the caller's variable.
// Fixtures used: self-contained table 69336, codeunit 69336
// BC versions: 27.5, 29.0

table 69336 "PU Tf Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
        field(4; Kind; Option) { OptionMembers = Zero,One,Two; }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 69336 "PU TestField Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryTest(var Row: Record "PU Tf Row"; FieldNo: Integer; Info: ErrorInfo)
    begin
        case FieldNo of
            2:
                Row.TestField(Name, Info);
            3:
                Row.TestField(Amount, Info);
            4:
                Row.TestField(Kind, Info);
        end;
    end;

    [Test]
    procedure TestField_ErrorInfo_Passing()
    var
        Row: Record "PU Tf Row";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Row.Name := 'x';
        Row.Amount := 5;
        Row.Kind := Row.Kind::One;
        Info := ErrorInfo.Create('custom message');
        Row.TestField(Name, Info);
        Row.TestField(Amount, Info);
        Row.TestField(Kind, Info);
        Row.TestField(Name, 'x', Info);
        Row.TestField(Amount, 5, Info);
        Row.TestField(Kind, Row.Kind::One, Info);
        Observer.Observe('no_error', 'ok');
        Observer.Observe('info_message_after', Info.Message());
        Observer.Expect('no_error', 'ok');
        Observer.Expect('info_message_after', 'custom message');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_ErrorInfo_BlankField_TextAndCode()
    var
        Row: Record "PU Tf Row";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Info := ErrorInfo.Create('custom message');
        asserterror Row.TestField(Name, Info);
        Observer.ObserveError('blank_text_custom');
        Info := ErrorInfo.Create();
        asserterror Row.TestField(Name, Info);
        Observer.ObserveError('blank_text_default_info');
        Info := ErrorInfo.Create('custom message');
        Row.Amount := 0;
        asserterror Row.TestField(Amount, Info);
        Observer.ObserveError('blank_amount_custom');
        asserterror Row.TestField(Kind, Info);
        Observer.ObserveError('blank_option_custom');
        asserterror Row.TestField(Name);
        Observer.ObserveError('without_info');
        Observer.Expect('blank_text_custom|text', 'Name must have a value in PU Tf Row: Id=0. It cannot be zero or empty.');
        Observer.Expect('blank_text_custom|code', 'TestField');
        Observer.Expect('blank_text_default_info|text', 'Name must have a value in PU Tf Row: Id=0. It cannot be zero or empty.');
        Observer.Expect('blank_text_default_info|code', 'TestField');
        Observer.Expect('blank_amount_custom|text', 'Amount must have a value in PU Tf Row: Id=0. It cannot be zero or empty.');
        Observer.Expect('blank_amount_custom|code', 'TestField');
        Observer.Expect('blank_option_custom|text', 'Kind must not be Zero in PU Tf Row: Id=0');
        Observer.Expect('blank_option_custom|code', 'TestField');
        Observer.Expect('without_info|text', 'Name must have a value in PU Tf Row: Id=0. It cannot be zero or empty.');
        Observer.Expect('without_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_ErrorInfoAndValue_WrongValue_TextAndCode()
    var
        Row: Record "PU Tf Row";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Row.Name := 'actual';
        Row.Amount := 5;
        Row.Kind := Row.Kind::One;
        Info := ErrorInfo.Create('custom message');
        asserterror Row.TestField(Name, 'expected', Info);
        Observer.ObserveError('wrong_text_custom');
        Info := ErrorInfo.Create();
        asserterror Row.TestField(Name, 'expected', Info);
        Observer.ObserveError('wrong_text_default_info');
        Info := ErrorInfo.Create('custom message');
        asserterror Row.TestField(Amount, 6, Info);
        Observer.ObserveError('wrong_amount_custom');
        asserterror Row.TestField(Kind, Row.Kind::Two, Info);
        Observer.ObserveError('wrong_option_custom');
        asserterror Row.TestField(Name, 'expected');
        Observer.ObserveError('wrong_text_without_info');
        Observer.Expect('wrong_text_custom|text', 'Name must be equal to ''expected''  in PU Tf Row: Id=0. Current value is ''actual''.');
        Observer.Expect('wrong_text_custom|code', 'TestField');
        Observer.Expect('wrong_text_default_info|text', 'Name must be equal to ''expected''  in PU Tf Row: Id=0. Current value is ''actual''.');
        Observer.Expect('wrong_text_default_info|code', 'TestField');
        Observer.Expect('wrong_amount_custom|text', 'Amount must be equal to ''6''  in PU Tf Row: Id=0. Current value is ''5''.');
        Observer.Expect('wrong_amount_custom|code', 'TestField');
        Observer.Expect('wrong_option_custom|text', 'Kind must be equal to ''Two''  in PU Tf Row: Id=0. Current value is ''One''.');
        Observer.Expect('wrong_option_custom|code', 'TestField');
        Observer.Expect('wrong_text_without_info|text', 'Name must be equal to ''expected''  in PU Tf Row: Id=0. Current value is ''actual''.');
        Observer.Expect('wrong_text_without_info|code', 'TestField');
        Observer.Verify();
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestField_ErrorInfo_InCollectScope()
    var
        Row: Record "PU Tf Row";
        Info: ErrorInfo;
        Errors: List of [ErrorInfo];
        One: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Info := ErrorInfo.Create('collectible message', true);
        Row.TestField(Name, Info);
        Row.TestField(Amount, Info);
        Row.Name := 'actual';
        Row.TestField(Name, 'expected', Info);
        Observer.Observe('has_errors', Format(HasCollectedErrors()));
        Errors := GetCollectedErrors(false);
        Observer.Observe('collected_count', Format(Errors.Count()));
        foreach One in Errors do
            Observer.Observe('collected', One.Message() + ' | type=' + Format(One.ErrorType()) + ' | fieldno=' + Format(One.FieldNo()) + ' | tableid=' + Format(One.TableId()));
        ClearCollectedErrors();
        Observer.Expect('has_errors', 'Yes');
        Observer.Expect('collected_count', '3');
        Observer.Expect('collected', 'collectible message | type=Client | fieldno=2 | tableid=69336');
        Observer.Expect('collected', 'collectible message | type=Client | fieldno=3 | tableid=69336');
        Observer.Expect('collected', 'collectible message | type=Client | fieldno=2 | tableid=69336');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_ErrorInfo_NotCollectible_InCollectScope()
    var
        Row: Record "PU Tf Row";
        Info: ErrorInfo;
        Observer: Codeunit "Probe Observer";
    begin
        Info := ErrorInfo.Create('plain message');
        asserterror Row.TestField(Name, Info);
        Observer.ObserveError('not_collectible');
        Observer.Observe('info_fieldno', Format(Info.FieldNo()));
        Observer.Observe('info_tableid', Format(Info.TableId()));
        Observer.Observe('info_message', Info.Message());
        Observer.Observe('info_collectible', Format(Info.Collectible()));
        Observer.Expect('not_collectible|text', 'Name must have a value in PU Tf Row: Id=0. It cannot be zero or empty.');
        Observer.Expect('not_collectible|code', 'TestField');
        Observer.Expect('info_fieldno', '0');
        Observer.Expect('info_tableid', '0');
        Observer.Expect('info_message', 'plain message');
        Observer.Expect('info_collectible', 'No');
        Observer.Verify();
    end;
}
