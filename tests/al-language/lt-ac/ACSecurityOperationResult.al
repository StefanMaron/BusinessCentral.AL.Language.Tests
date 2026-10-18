// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/securityoperationresult/securityoperationresult-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the SecurityOperationResult option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, Evaluate by name and by number, and the error text of Evaluate for an invalid name and ordinal. The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Settles #626 items 11 to 15 for SecurityOperationResult.
// BC versions: 27, 28, 29

codeunit 77514 "LT AC SecOp Result Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_SecurityOperationResult_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_Success', Format(SecurityOperationResult::Success));
        Observer.Observe('text_ClientError', Format(SecurityOperationResult::ClientError));
        Observer.Observe('text_Failure', Format(SecurityOperationResult::Failure));
        Observer.Observe('text_Timeout', Format(SecurityOperationResult::Timeout));
        Observer.Observe('ordinal_Success', Format(SecurityOperationResult::Success, 0, 2));
        Observer.Observe('ordinal_ClientError', Format(SecurityOperationResult::ClientError, 0, 2));
        Observer.Observe('ordinal_Failure', Format(SecurityOperationResult::Failure, 0, 2));
        Observer.Observe('ordinal_Timeout', Format(SecurityOperationResult::Timeout, 0, 2));
        Observer.Observe('number_Success', Format(SecurityOperationResult::Success, 0, 1));
        Observer.Observe('number_ClientError', Format(SecurityOperationResult::ClientError, 0, 1));
        Observer.Observe('number_Failure', Format(SecurityOperationResult::Failure, 0, 1));
        Observer.Observe('number_Timeout', Format(SecurityOperationResult::Timeout, 0, 1));
        Observer.Finish();
    end;

    [Test]
    procedure AC_SecurityOperationResult_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: SecurityOperationResult;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := SecurityOperationResult::Timeout;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = SecurityOperationResult::Timeout));
        Observer.Observe('eq_first', Format(V = SecurityOperationResult::Success));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure AC_SecurityOperationResult_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: SecurityOperationResult;
    begin
        V := SecurityOperationResult::Success;
        Observer.Observe('case_Success', CaseName(V));
        V := SecurityOperationResult::ClientError;
        Observer.Observe('case_ClientError', CaseName(V));
        V := SecurityOperationResult::Failure;
        Observer.Observe('case_Failure', CaseName(V));
        V := SecurityOperationResult::Timeout;
        Observer.Observe('case_Timeout', CaseName(V));
        Observer.Finish();
    end;

    local procedure CaseName(V: SecurityOperationResult): Text
    begin
        case V of
            SecurityOperationResult::Success:
                exit('is_Success');
            SecurityOperationResult::ClientError:
                exit('is_ClientError');
            SecurityOperationResult::Failure:
                exit('is_Failure');
            SecurityOperationResult::Timeout:
                exit('is_Timeout');
            else
                exit('other');
        end;
    end;
}

codeunit 77515 "LT AC SecOp Result Eval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_SecurityOperationResult_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: SecurityOperationResult;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := Evaluate(V, 'Success');
        Observer.Observe('name_Success', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'ClientError');
        Observer.Observe('name_ClientError', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Failure');
        Observer.Observe('name_Failure', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Timeout');
        Observer.Observe('name_Timeout', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'clienterror');
        Observer.Observe('name_lowercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'CLIENTERROR');
        Observer.Observe('name_uppercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '0');
        Observer.Observe('number_0', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '1');
        Observer.Observe('number_1', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '2');
        Observer.Observe('number_2', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, '3');
        Observer.Observe('number_3', Format(Ok) + '/' + Format(V, 0, 2));
        Observer.Finish();
    end;

    [Test]
    procedure AC_SecurityOperationResult_EvaluateInvalid()
    var
        Observer: Codeunit "Probe Observer";
        V: SecurityOperationResult;
    begin
        Clear(V);
        if Evaluate(V, 'Bogus') then
            Observer.Observe('bogus_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('bogus');
        Clear(V);
        if Evaluate(V, '') then
            Observer.Observe('empty_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('empty');
        Clear(V);
        if Evaluate(V, '4') then
            Observer.Observe('past_end_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('past_end');
        Clear(V);
        if Evaluate(V, '99') then
            Observer.Observe('large_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('large');
        Clear(V);
        if Evaluate(V, '-1') then
            Observer.Observe('negative_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('negative');
        Clear(V);
        if Evaluate(V, ' ClientError') then
            Observer.Observe('space_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('space');
        Clear(V);
        if Evaluate(V, '1.5') then
            Observer.Observe('decimal_ok', Format(V, 0, 2))
        else
            Observer.ObserveError('decimal');
        Observer.Finish();
    end;
}
