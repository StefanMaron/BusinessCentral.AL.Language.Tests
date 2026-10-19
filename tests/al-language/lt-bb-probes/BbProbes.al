// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods/devenv-method-overloading
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects of BbObjects.al (80850 to 80855)
// Probe: corpus issue 653 item 2 (which Bump a Report variable calls when the base report has Bump(Integer) and its extension Bump(Text)),
//   item 9 (an enum value passed by value to a parameter of another enum type with AssignmentCompatibility = true), item 10 (a one-character
//   literal is a Char: it compiles into Integer, BigInteger and Decimal; 'xy' is refused, must-not-compile case 1251), and issue 639 items 10 to
//   12 and 18 (the page with a field FileUploadAction, a system part EntityName/EntitySetName and HelpLink opens in a TestPage).
// BC versions: 27, 28, 29
codeunit 80860 "LT BB Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure ReportExt_OverloadByParameterType()
    var
        R: Report "LT BB Base Report";
        T: Text;
        C: Code[10];
        Ch: Char;
    begin
        T := 'abc';
        C := 'CODE';
        Ch := 'q';
        Observer.Observe('int', R.Bump(7));
        Observer.Observe('text', R.Bump(T));
        Observer.Observe('code', R.Bump(C));
        Observer.Observe('char literal', R.Bump('x'));
        Observer.Observe('char var', R.Bump(Ch));
        Observer.Finish();
    end;

    [Test]
    procedure CharLiteral_ToNumbers()
    var
        I: Integer;
        BI: BigInteger;
        D: Decimal;
    begin
        I := 'x';
        BI := 'x';
        D := 'x';
        Observer.Observe('integer', Format(I));
        Observer.Observe('biginteger', Format(BI));
        Observer.Observe('decimal', Format(D));
        Observer.Finish();
    end;

    local procedure Take(B: Enum "LT BB Enum B"): Text
    begin
        exit(Format(B.AsInteger()) + '|' + Format(B));
    end;

    [TryFunction]
    local procedure TryTake(A: Enum "LT BB Enum A"; var Shown: Text)
    begin
        Shown := Take(A);
    end;

    [Test]
    procedure Enum_ByValueToCompatibleEnum()
    var
        A: Enum "LT BB Enum A";
        Shown: Text;
    begin
        A := A::One;
        Observer.Observe('one', Take(A));
        A := A::Five;
        ClearLastError();
        if TryTake(A, Shown) then
            Observer.Observe('five', Shown)
        else
            Observer.ObserveError('five');
        Observer.Finish();
    end;

    [Test]
    procedure Page_FieldFileUploadAction_SystemPartEntityName_HelpLink()
    var
        Row: Record "LT BB Row";
        TP: TestPage "LT BB Controls";
    begin
        Row.DeleteAll();
        Row.Id := 3;
        Row.Txt := 'three';
        Row.Insert();
        TP.OpenView();
        TP.First();
        Observer.Observe('id', TP.Id.Value());
        Observer.Observe('txt', TP.Txt.Value());
        Observer.Observe('id visible', Format(TP.Id.Visible()));
        TP.Close();
        Observer.Finish();
    end;
}
