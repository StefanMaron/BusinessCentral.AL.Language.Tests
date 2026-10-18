// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/pagebackgroundtaskerrorlevel/pagebackgroundtaskerrorlevel-option
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: the PageBackgroundTaskErrorLevel option type: Format of every member as text (Format 0,0), as ordinal (Format 0,2) and as number text (Format 0,1), a case statement over every member, Evaluate by name and by number, and the error text of Evaluate for an invalid name and ordinal. The type is option-like: AsInteger does not exist and an Integer is not assignable (AL0132 and AL0122 at compile time).
//   Settles #626 items 11 to 15 for PageBackgroundTaskErrorLevel.
// BC versions: 27, 28, 29

codeunit 77516 "LT AC PBT Error Level Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Format()
    var
        Observer: Codeunit "Probe Observer";
    begin

        Observer.Observe('text_Error', Format(PageBackgroundTaskErrorLevel::Error));
        Observer.Observe('text_Warning', Format(PageBackgroundTaskErrorLevel::Warning));
        Observer.Observe('text_Ignore', Format(PageBackgroundTaskErrorLevel::Ignore));
        Observer.Observe('ordinal_Error', Format(PageBackgroundTaskErrorLevel::Error, 0, 2));
        Observer.Observe('ordinal_Warning', Format(PageBackgroundTaskErrorLevel::Warning, 0, 2));
        Observer.Observe('ordinal_Ignore', Format(PageBackgroundTaskErrorLevel::Ignore, 0, 2));
        Observer.Observe('number_Error', Format(PageBackgroundTaskErrorLevel::Error, 0, 1));
        Observer.Observe('number_Warning', Format(PageBackgroundTaskErrorLevel::Warning, 0, 1));
        Observer.Observe('number_Ignore', Format(PageBackgroundTaskErrorLevel::Ignore, 0, 1));
        Observer.Finish();
    end;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Variable()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
    begin

        Observer.Observe('default', Format(V));
        Observer.Observe('default_ordinal', Format(V, 0, 2));
        V := PageBackgroundTaskErrorLevel::Ignore;
        Observer.Observe('last', Format(V));
        Observer.Observe('last_ordinal', Format(V, 0, 2));
        Observer.Observe('eq_last', Format(V = PageBackgroundTaskErrorLevel::Ignore));
        Observer.Observe('eq_first', Format(V = PageBackgroundTaskErrorLevel::Error));
        Clear(V);
        Observer.Observe('cleared', Format(V));
        Observer.Finish();
    end;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Case()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
    begin
        V := PageBackgroundTaskErrorLevel::Error;
        Observer.Observe('case_Error', CaseName(V));
        V := PageBackgroundTaskErrorLevel::Warning;
        Observer.Observe('case_Warning', CaseName(V));
        V := PageBackgroundTaskErrorLevel::Ignore;
        Observer.Observe('case_Ignore', CaseName(V));
        Observer.Finish();
    end;

    local procedure CaseName(V: PageBackgroundTaskErrorLevel): Text
    begin
        case V of
            PageBackgroundTaskErrorLevel::Error:
                exit('is_Error');
            PageBackgroundTaskErrorLevel::Warning:
                exit('is_Warning');
            PageBackgroundTaskErrorLevel::Ignore:
                exit('is_Ignore');
            else
                exit('other');
        end;
    end;
}

codeunit 77517 "LT AC PBT Error Level Eval"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
        Ok: Boolean;
    begin
        Clear(V);
        Ok := Evaluate(V, 'Error');
        Observer.Observe('name_Error', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Warning');
        Observer.Observe('name_Warning', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'Ignore');
        Observer.Observe('name_Ignore', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'warning');
        Observer.Observe('name_lowercase', Format(Ok) + '/' + Format(V, 0, 2));
        Clear(V);
        Ok := Evaluate(V, 'WARNING');
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
        Observer.Finish();
    end;

    [Test]
    procedure AC_PageBackgroundTaskErrorLevel_EvaluateInvalid()
    var
        Observer: Codeunit "Probe Observer";
        V: PageBackgroundTaskErrorLevel;
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
        if Evaluate(V, '3') then
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
        if Evaluate(V, ' Warning') then
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
