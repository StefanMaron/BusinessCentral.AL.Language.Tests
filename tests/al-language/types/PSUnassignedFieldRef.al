// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-data-type
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier produced. Other BC versions were not measured.
//
// A FieldRef variable that was never assigned (no RecordRef.Field call): Name(), Number(), Value(), Type(), Length() and Record() RAISE
// "Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized." with the code NotInitialized (BC does not answer blanks, whatever the Tests-ERM table is).
// A FieldRef taken from the RecordRef of an EMPTY table works: Number, Name, Type, Record().Number() answer, and Value() is the field's default (0 for an Integer).
// Fixtures used: PS Modal Row (69545) from PSModalPageHandlerTyped.al, codeunit 69558
// BC versions: 27.5

codeunit 69558 "PS FieldRef Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryName(var FldRef: FieldRef; var Result: Text)
    begin
        Result := FldRef.Name();
    end;

    [TryFunction]
    local procedure TryNumber(var FldRef: FieldRef; var Result: Text)
    begin
        Result := Format(FldRef.Number());
    end;

    [TryFunction]
    local procedure TryValue(var FldRef: FieldRef; var Result: Text)
    begin
        Result := Format(FldRef.Value());
    end;

    [TryFunction]
    local procedure TryType(var FldRef: FieldRef; var Result: Text)
    begin
        Result := Format(FldRef.Type());
    end;

    [TryFunction]
    local procedure TryLength(var FldRef: FieldRef; var Result: Text)
    begin
        Result := Format(FldRef.Length());
    end;

    [TryFunction]
    local procedure TryRecord(var FldRef: FieldRef; var Result: Text)
    var
        RecRef: RecordRef;
    begin
        RecRef := FldRef.Record();
        Result := Format(RecRef.Number());
    end;

    local procedure Outcome(Ok: Boolean; Value: Text): Text
    begin
        if Ok then
            exit('ok:[' + Value + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure UnassignedFieldRef_Members()
    var
        FldRef: FieldRef;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('name', Outcome(TryName(FldRef, Result), Result));
        Observer.Observe('number', Outcome(TryNumber(FldRef, Result), Result));
        Observer.Observe('value', Outcome(TryValue(FldRef, Result), Result));
        Observer.Observe('type', Outcome(TryType(FldRef, Result), Result));
        Observer.Observe('length', Outcome(TryLength(FldRef, Result), Result));
        Observer.Observe('record', Outcome(TryRecord(FldRef, Result), Result));
        Observer.Expect('name', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('number', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('value', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('type', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('length', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Expect('record', 'error:Microsoft.Dynamics.Nav.Runtime.NavFieldRef variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure FieldRefOfEmptyTable_Members()
    var
        Row: Record "PS Modal Row";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        RecRef.Open(Database::"PS Modal Row");
        Observer.Observe('empty', Format(RecRef.IsEmpty()));
        FldRef := RecRef.Field(1);
        Observer.Observe('number', Format(FldRef.Number()));
        Observer.Observe('name', FldRef.Name());
        Observer.Observe('value', '[' + Format(FldRef.Value()) + ']');
        Observer.Observe('type', Format(FldRef.Type()));
        Observer.Observe('record_number', Format(FldRef.Record().Number()));
        Observer.Expect('empty', 'Yes');
        Observer.Expect('number', '1');
        Observer.Expect('name', 'Id');
        Observer.Expect('value', '[0]');
        Observer.Expect('type', 'Integer');
        Observer.Expect('record_number', '69545');
        Observer.Verify();
    end;
}
