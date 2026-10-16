// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-strsubstno-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained objects
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: StrSubstNo with missing arguments, %%, field width placeholders, repeated and high-numbered placeholders, surplus arguments, texts with %
// BC versions: 29 (27 and 28 by CI)

codeunit 73528 "LT P86 StrSubstNo"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySub(Fmt: Text; N: Integer; var R: Text)
    begin
        case N of
            0:
                R := StrSubstNo(Fmt);
            1:
                R := StrSubstNo(Fmt, 'a');
            2:
                R := StrSubstNo(Fmt, 'a', 'b');
            3:
                R := StrSubstNo(Fmt, 'a', 'b', 'c');
            4:
                R := StrSubstNo(Fmt, 'a', 'b', 'c', 'd');
        end;
    end;

    local procedure S(Fmt: Text; N: Integer): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TrySub(Fmt, N, R) then
            exit('ok|' + R);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R);
    end;

    [TryFunction]
    local procedure TrySubNum(Fmt: Text; A1: Integer; A2: Decimal; var R: Text)
    begin
        R := StrSubstNo(Fmt, A1, A2);
    end;

    local procedure SN(Fmt: Text; A1: Integer; A2: Decimal): Text
    var
        R: Text;
    begin
        R := '<unset>';
        if TrySubNum(Fmt, A1, A2, R) then
            exit('ok|' + R);
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + R);
    end;

    [Test]
    procedure Sub_MissingArg()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('%1 %2 %3', 2));
        Observer.Observe('t2', S('%3', 2));
        Observer.Observe('t3', S('%3', 0));
        Observer.Observe('t4', S('%2', 1));
        Observer.Observe('t5', S('%1', 0));
        Observer.Observe('t6', S('x%3y', 2));
        Observer.Observe('t7', S('%1 %3', 3));
        Observer.Observe('t8', S('%1%2%3', 1));
        Observer.Observe('t9', S('%4', 3));
        Observer.Observe('t10', S('%1 %2 %3 %4', 4));
        Observer.Observe('t11', S('%2 %1', 2));
        Observer.Observe('t12', S('%3 %2 %1', 3));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_Percent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('%%', 0));
        Observer.Observe('t2', S('%%', 1));
        Observer.Observe('t3', S('%%1', 1));
        Observer.Observe('t4', S('%%%1', 1));
        Observer.Observe('t5', S('100%', 0));
        Observer.Observe('t6', S('100%', 1));
        Observer.Observe('t7', S('%', 0));
        Observer.Observe('t8', S('%', 1));
        Observer.Observe('t9', S('%1%', 1));
        Observer.Observe('t10', S('%a', 1));
        Observer.Observe('t11', S('%0', 1));
        Observer.Observe('t12', S('%-1', 1));
        Observer.Observe('t13', S('% 1', 1));
        Observer.Observe('t14', S('%1%%2', 2));
        Observer.Observe('t15', S('%%%%', 0));
        Observer.Observe('t16', S('50%% of %1', 1));
        Observer.Observe('t17', S('%1 %% %2', 2));
        Observer.Observe('t18', S('%%1 %1', 1));
        Observer.Observe('t19', S('%01', 1));
        Observer.Observe('t20', S('%001', 1));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_Repeated()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('%1 %1 %1', 1));
        Observer.Observe('t2', S('%1%1', 1));
        Observer.Observe('t3', S('%2 %1 %2', 2));
        Observer.Observe('t4', S('%1 %2 %1 %2', 2));
        Observer.Observe('t5', S('%1-%1-%1-%1', 1));
        Observer.Observe('t6', S('%2%2', 2));
        Observer.Observe('t7', S('%3 %3', 3));
        Observer.Observe('t8', S('%1%2%3%1', 3));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_Surplus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('x', 1));
        Observer.Observe('t2', S('x', 3));
        Observer.Observe('t3', S('%1', 2));
        Observer.Observe('t4', S('%1', 4));
        Observer.Observe('t5', S('%2', 4));
        Observer.Observe('t6', S('', 2));
        Observer.Observe('t7', S('', 0));
        Observer.Observe('t8', S('%1 %2', 3));
        Observer.Observe('t9', S('%4', 4));
        Observer.Observe('t10', S('plain text', 2));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_FieldWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('#1####', 1));
        Observer.Observe('t2', S('#1####|', 1));
        Observer.Observe('t3', S('#1#', 1));
        Observer.Observe('t4', S('#1', 1));
        Observer.Observe('t5', S('#####', 1));
        Observer.Observe('t6', S('#1####x#2####', 2));
        Observer.Observe('t7', S('[#1######]', 1));
        Observer.Observe('t8', S('#2####', 1));
        Observer.Observe('t9', S('#1####%1', 1));
        Observer.Observe('t10', S('%1#1####', 1));
        Observer.Observe('t11', S('#1###########################', 1));
        Observer.Observe('t12', S('a#1#', 3));
        Observer.Observe('t13', S('#3###', 3));
        Observer.Observe('t14', S('#1####', 0));
        Observer.Observe('t15', S('#1####', 2));
        Observer.Observe('t16', S('# 1###', 1));
        Observer.Observe('t17', S('#0###', 1));
        Observer.Observe('t18', S('##1##', 1));
        Observer.Observe('t19', S('#1#### #1####', 1));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_Empty()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', S('', 0));
        Observer.Observe('t2', S('', 1));
        Observer.Observe('t3', S(' ', 1));
        Observer.Observe('t4', S('%1', 1));
        Observer.Observe('t5', S(' %1 ', 1));
        Observer.Observe('t6', S('%1%2', 2));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', SN('%1 %2', 5, 1.5));
        Observer.Observe('t2', SN('%1|%2', -5, -1234567.891));
        Observer.Observe('t3', SN('#1####|#2####', 5, 1.5));
        Observer.Observe('t4', SN('#1####|#2####', -5, -1.5));
        Observer.Observe('t5', SN('#1##|#2##', 123456, 123456.789));
        Observer.Observe('t6', SN('%2 %2', 0, 0));
        Observer.Observe('t7', SN('%1', 1000000, 0));
        Observer.Observe('t8', SN('#2####|', 0, 12.3456789));
        Observer.Observe('t9', SN('%3', 1, 2));
        Observer.Observe('t10', SN('%%2 %2', 1, 2.5));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_TenArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('t1', StrSubstNo('%1%2%3%4%5%6%7%8%9%10', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t2', StrSubstNo('%10', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t3', StrSubstNo('%10 %1', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t4', StrSubstNo('%11', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t5', StrSubstNo('%1%2%3%4%5%6%7%8%9%10%11', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t6', StrSubstNo('%1', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'));
        Observer.Observe('t7', StrSubstNo('%10', 'a'));
        Observer.Observe('t8', StrSubstNo('%1%0', 'a'));
        Observer.Finish();
    end;

    [Test]
    procedure Sub_ArgumentWithPercent()
    var
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := '100%';
        Observer.Observe('t1', StrSubstNo('%1', P));
        Observer.Observe('t2', StrSubstNo('%1 %2', P, '%1'));
        Observer.Observe('t3', StrSubstNo('%1', '%2'));
        Observer.Observe('t4', StrSubstNo('%1', '%%'));
        Observer.Observe('t5', StrSubstNo('%1', '#1####'));
        Observer.Observe('t6', StrSubstNo('#1####|', P));
        Observer.Observe('t7', StrSubstNo('%1%2', '%2', 'x'));
        Observer.Observe('t8', StrSubstNo(P));
        Observer.Observe('t9', StrSubstNo(P, 'a'));
        Observer.Observe('t10', StrSubstNo('%1', ''));
        Observer.Finish();
    end;
}

