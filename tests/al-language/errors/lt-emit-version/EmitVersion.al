// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); helper codeunit 71928 (not a test codeunit)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the emit version number of the missing-object error (the Observer scrubs it in the text, so it is cut out here and observed as a number: the value, the value div 1000, mod 1000), the same number for a missing codeunit, table (RecordRef.Open), page and report, and the caller named in the text when the call runs in the test codeunit and in a helper codeunit.
// BC versions: 29 (27 and 28 by CI; the number differs per major: record each major's value)

codeunit 71928 "LT P160 Missing Caller"
{
    procedure RunMissingCodeunit()
    begin
        Codeunit.Run(71998);
    end;
}

codeunit 71927 "LT P160 Emit Version"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EmitVersion(Msg: Text): Text
    var
        Marker: Text;
        P: Integer;
        Rest: Text;
        Digits: Text;
        i: Integer;
    begin
        Marker := 'compiled with emit version ';
        P := StrPos(Msg, Marker);
        if P = 0 then
            exit('no marker');
        Rest := CopyStr(Msg, P + StrLen(Marker));
        for i := 1 to StrLen(Rest) do begin
            if StrPos('0123456789', CopyStr(Rest, i, 1)) = 0 then
                break;
            Digits += CopyStr(Rest, i, 1);
        end;
        exit(Digits);
    end;

    local procedure Caller(Msg: Text): Text
    var
        Marker: Text;
        P: Integer;
        Q: Integer;
        Rest: Text;
    begin
        Marker := 'from the object ';
        P := StrPos(Msg, Marker);
        if P = 0 then
            exit('no marker');
        Rest := CopyStr(Msg, P + StrLen(Marker));
        Q := StrPos(Rest, '. An object with that ID');
        if Q = 0 then
            exit('no end: ' + CopyStr(Rest, 1, 100));
        exit(CopyStr(Rest, 1, Q - 1));
    end;

    local procedure ObserveVersion(var Observer: Codeunit "Probe Observer"; Tag: Text; Msg: Text)
    var
        Number: Integer;
        V: Text;
    begin
        V := EmitVersion(Msg);
        Observer.Observe(Tag + ' digits', V);
        if Evaluate(Number, V) then begin
            Observer.Observe(Tag + ' div 1000', Format(Number div 1000));
            Observer.Observe(Tag + ' mod 1000', Format(Number mod 1000));
        end;
    end;

    [Test]
    procedure Codeunit_EmitVersionNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Codeunit.Run(71998);
        ObserveVersion(Observer, 'codeunit', GetLastErrorText());
        Observer.Observe('codeunit code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('codeunit digits', '29022');
        Observer.Expect('codeunit div 1000', '29');
        Observer.Expect('codeunit mod 1000', '22');
        Observer.Expect('codeunit code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Table_EmitVersionNumber()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        asserterror RecRef.Open(71998);
        ObserveVersion(Observer, 'table', GetLastErrorText());
        Observer.Observe('table code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('table digits', '29022');
        Observer.Expect('table div 1000', '29');
        Observer.Expect('table mod 1000', '22');
        Observer.Expect('table code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Page_EmitVersionNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Page.Run(71998);
        ObserveVersion(Observer, 'page', GetLastErrorText());
        Observer.Observe('page code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('page digits', '29022');
        Observer.Expect('page div 1000', '29');
        Observer.Expect('page mod 1000', '22');
        Observer.Expect('page code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Report_EmitVersionNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Report.Run(71998);
        ObserveVersion(Observer, 'report', GetLastErrorText());
        Observer.Observe('report code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('report digits', '29022');
        Observer.Expect('report div 1000', '29');
        Observer.Expect('report mod 1000', '22');
        Observer.Expect('report code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Caller_TestCodeunitAndHelperCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P160 Missing Caller";
    begin
        asserterror Codeunit.Run(71998);
        Observer.Observe('caller in the test codeunit', Caller(GetLastErrorText()));
        ClearLastError();
        asserterror Helper.RunMissingCodeunit();
        Observer.Observe('caller in the helper codeunit', Caller(GetLastErrorText()));
        ClearLastError();
        Observer.Expect('caller in the test codeunit', 'LT P160 Emit Version');
        Observer.Expect('caller in the helper codeunit', 'LT P160 Emit Version');
        Observer.Verify();
    end;
}
