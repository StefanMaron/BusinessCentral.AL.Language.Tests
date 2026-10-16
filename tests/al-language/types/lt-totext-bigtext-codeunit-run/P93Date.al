// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Date.Day, Month, Year, ToText (no argument and Invariant true/false) against Format, for normal, closing and 0D dates
// BC versions: 29 (27 and 28 by CI)

codeunit 70320 "LT P93 Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryParts(D: Date; var R: Text)
    begin
        R := Format(D.Day()) + '|' + Format(D.Month()) + '|' + Format(D.Year());
    end;

    [TryFunction]
    local procedure TryToText(D: Date; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := D.ToText();
            1:
                R := D.ToText(true);
            2:
                R := D.ToText(false);
        end;
    end;

    local procedure Parts(D: Date): Text
    var
        R: Text;
    begin
        if TryParts(D, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TT(D: Date; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryToText(D, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DayMonthYear_Normal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('mid', Parts(20240315D));
        Observer.Observe('first', Parts(20240101D));
        Observer.Observe('dec31', Parts(20231231D));
        Observer.Observe('feb29', Parts(20240229D));
        Observer.Observe('feb28', Parts(20230228D));
        asserterror Observer.Observe('min', Parts(00010101D));
        Observer.ObserveError('af60');
        Observer.Observe('max', Parts(99991231D));
        Observer.Observe('y1753', Parts(17530101D));
        Observer.Observe('y1900', Parts(19000301D));
        Observer.Observe('apr30', Parts(20240430D));
        Observer.Finish();
    end;

    [Test]
    procedure DayMonthYear_Zero()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('zero-var', Parts(D));
        Observer.Observe('zero-lit', Parts(0D));
        Observer.Observe('zero-format', Format(D));
        Observer.Observe('zero-isdefault', Format(D = 0D));
        Observer.Finish();
    end;

    [Test]
    procedure DayMonthYear_ClosingDates()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := ClosingDate(20231231D);
        Observer.Observe('closing-parts', Parts(D));
        Observer.Observe('closing-format', Format(D));
        Observer.Observe('closing-isclosing', Format(D = ClosingDate(20231231D)));
        Observer.Observe('closing-eq-normal', Format(D = 20231231D));
        Observer.Observe('closing-tt', TT(D, 0));
        Observer.Observe('closing-tt-inv', TT(D, 1));
        Observer.Observe('closing-tt-false', TT(D, 2));
        Observer.Observe('closing-feb29', Parts(ClosingDate(20240229D)));
        Observer.Observe('normalize', Format(NormalDate(D)));
        Observer.Finish();
    end;

    [Test]
    procedure ToText_Normal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240315D;
        Observer.Observe('tt', TT(D, 0));
        Observer.Observe('tt-true', TT(D, 1));
        Observer.Observe('tt-false', TT(D, 2));
        Observer.Observe('format', Format(D));
        Observer.Observe('format-9', Format(D, 0, 9));
        Observer.Observe('format-0', Format(D, 0, 0));
        Observer.Observe('format-1', Format(D, 0, 1));
        Observer.Observe('format-2', Format(D, 0, 2));
        Observer.Observe('format-4', Format(D, 0, 4));
        Observer.Observe('format-custom', Format(D, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Finish();
    end;

    [Test]
    procedure ToText_Closing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dec31', TT(20231231D, 0));
        Observer.Observe('dec31-true', TT(20231231D, 1));
        Observer.Observe('dec31-false', TT(20231231D, 2));
        Observer.Observe('dec31-format-9', Format(20231231D, 0, 9));
        Observer.Observe('feb29', TT(20240229D, 0));
        Observer.Observe('feb29-true', TT(20240229D, 1));
        Observer.Observe('feb29-false', TT(20240229D, 2));
        Observer.Observe('feb29-format', Format(20240229D));
        Observer.Observe('feb29-format-9', Format(20240229D, 0, 9));
        asserterror Observer.Observe('min', TT(00010101D, 0));
        Observer.ObserveError('af135');
        asserterror Observer.Observe('min-true', TT(00010101D, 1));
        Observer.ObserveError('af137');
        Observer.Observe('max', TT(99991231D, 0));
        Observer.Observe('max-true', TT(99991231D, 1));
        Observer.Finish();
    end;

    [Test]
    procedure ToText_Zero()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('tt', TT(D, 0));
        Observer.Observe('tt-true', TT(D, 1));
        Observer.Observe('tt-false', TT(D, 2));
        Observer.Observe('format', Format(D));
        Observer.Observe('format-9', Format(D, 0, 9));
        Observer.Observe('format-0', Format(D, 0, 0));
        Observer.Observe('format-len', Format(StrLen(Format(D, 0, 9))));
        Observer.Finish();
    end;
}
