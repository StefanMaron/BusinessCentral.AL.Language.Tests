// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 80004; writer QS: table 87356 (tests QS_*)
// Probe: observed on the corpus CI matrix; every literal asserted below is what the BC service tier produced.
// Facts: Format(D, 0, '<Precision,2:2><Standard Format,2>') for a Decimal D: 0, 1234.5, -1, and the rounding and grouping edges 1234.567,
// 0.005, 1234567.1 and -0.5.
// BC versions: 27, 28, 29

// Writer QS: Decimal fields with AutoFormatType 1 (amount), 2 (unit amount), 10 with an AutoFormatExpression, and DecimalPlaces 0:5.
table 87356 "LT QS Std Fmt Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amt; Decimal) { AutoFormatType = 1; }
        field(3; UnitAmt; Decimal) { AutoFormatType = 2; }
        field(4; Custom; Decimal) { AutoFormatType = 10; AutoFormatExpression = '<Precision,1:1><Standard Format,0>'; }
        field(5; Dec5; Decimal) { DecimalPlaces = 0 : 5; }
        field(6; Plain; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 80004 "LT AT Precision Std Format 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure F(D: Decimal): Text
    begin
        exit(Format(D, 0, '<Precision,2:2><Standard Format,2>'));
    end;

    [Test]
    procedure AT_Precision22_StandardFormat2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('0', F(0));
        Observer.Observe('1234.5', F(1234.5));
        Observer.Observe('-1', F(-1));
        Observer.Observe('1234.567', F(1234.567));
        Observer.Observe('0.005', F(0.005));
        Observer.Observe('1234567.1', F(1234567.1));
        Observer.Observe('-0.5', F(-0.5));
        Observer.Expect('0', '0.00');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('1234.567', '1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('1234567.1', '1234567.10');
        Observer.Expect('-0.5', '-0.50');
        Observer.Verify();
    end;

    local procedure QsObserveValues(var Observer: Codeunit "Probe Observer"; Spec: Text)
    var
        D: Decimal;
    begin
        D := 0;
        Observer.Observe('0', Format(D, 0, Spec));
        D := 1;
        Observer.Observe('1', Format(D, 0, Spec));
        D := -1;
        Observer.Observe('-1', Format(D, 0, Spec));
        D := 10;
        Observer.Observe('10', Format(D, 0, Spec));
        D := 10.00000;
        Observer.Observe('10.00000', Format(D, 0, Spec));
        D := 0.1;
        Observer.Observe('0.1', Format(D, 0, Spec));
        D := 1234.5;
        Observer.Observe('1234.5', Format(D, 0, Spec));
        D := -1234.567;
        Observer.Observe('-1234.567', Format(D, 0, Spec));
        D := 0.005;
        Observer.Observe('0.005', Format(D, 0, Spec));
        D := 0.015;
        Observer.Observe('0.015', Format(D, 0, Spec));
        D := 0.025;
        Observer.Observe('0.025', Format(D, 0, Spec));
        D := -0.005;
        Observer.Observe('-0.005', Format(D, 0, Spec));
        D := 0.004999;
        Observer.Observe('0.004999', Format(D, 0, Spec));
        D := 999999.995;
        Observer.Observe('999999.995', Format(D, 0, Spec));
        D := 123456789012.345;
        Observer.Observe('123456789012.345', Format(D, 0, Spec));
        D := -99999999999999.99;
        Observer.Observe('-99999999999999.99', Format(D, 0, Spec));
        Evaluate(D, '10.00000', 9);
        Observer.Observe('evaluated 10.00000', Format(D, 0, Spec));
        D := 1 / 3;
        Observer.Observe('1/3', Format(D, 0, Spec));
    end;

    [Test]
    procedure QS_P22S2_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S2_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_S2_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0');
        Observer.Expect('1', '1');
        Observer.Expect('-1', '-1');
        Observer.Expect('10', '10');
        Observer.Expect('10.00000', '10');
        Observer.Expect('0.1', '0.1');
        Observer.Expect('1234.5', '1234.5');
        Observer.Expect('-1234.567', '-1234.567');
        Observer.Expect('0.005', '0.005');
        Observer.Expect('0.015', '0.015');
        Observer.Expect('0.025', '0.025');
        Observer.Expect('-0.005', '-0.005');
        Observer.Expect('0.004999', '0.004999');
        Observer.Expect('999999.995', '999999.995');
        Observer.Expect('123456789012.345', '123456789012.345');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10');
        Observer.Expect('1/3', '0.333333333333333333');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S0_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S0_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S1_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S1_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S9_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S9_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        QsObserveValues(Observer, '<Precision,2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S2_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S2_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_S2_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Standard Format,2>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0');
        Observer.Expect('1', '1');
        Observer.Expect('-1', '-1');
        Observer.Expect('10', '10');
        Observer.Expect('10.00000', '10');
        Observer.Expect('0.1', '0.1');
        Observer.Expect('1234.5', '1234.5');
        Observer.Expect('-1234.567', '-1234.567');
        Observer.Expect('0.005', '0.005');
        Observer.Expect('0.015', '0.015');
        Observer.Expect('0.025', '0.025');
        Observer.Expect('-0.005', '-0.005');
        Observer.Expect('0.004999', '0.004999');
        Observer.Expect('999999.995', '999999.995');
        Observer.Expect('123456789012.345', '123456789012.345');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10');
        Observer.Expect('1/3', '0.333333333333333333');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S0_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S0_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,0>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1,234.50');
        Observer.Expect('-1234.567', '-1,234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1,000,000.00');
        Observer.Expect('123456789012.345', '123,456,789,012.35');
        Observer.Expect('-99999999999999.99', '-99,999,999,999,999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S1_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S1_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,1>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P22S9_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2:2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_P2S9_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        QsObserveValues(Observer, '<Precision,2><Standard Format,9>');
        GlobalLanguage(Orig);
        Observer.Expect('0', '0.00');
        Observer.Expect('1', '1.00');
        Observer.Expect('-1', '-1.00');
        Observer.Expect('10', '10.00');
        Observer.Expect('10.00000', '10.00');
        Observer.Expect('0.1', '0.10');
        Observer.Expect('1234.5', '1234.50');
        Observer.Expect('-1234.567', '-1234.57');
        Observer.Expect('0.005', '0.01');
        Observer.Expect('0.015', '0.02');
        Observer.Expect('0.025', '0.03');
        Observer.Expect('-0.005', '-0.01');
        Observer.Expect('0.004999', '0.00');
        Observer.Expect('999999.995', '1000000.00');
        Observer.Expect('123456789012.345', '123456789012.35');
        Observer.Expect('-99999999999999.99', '-99999999999999.99');
        Observer.Expect('evaluated 10.00000', '10.00');
        Observer.Expect('1/3', '0.33');
        Observer.Verify();
    end;

    [Test]
    procedure QS_AutoFormatFields_EnUs()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QS Std Fmt Row";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1033);
        Row.Amt := 1234.5678;
        Row.UnitAmt := 1234.5678;
        Row.Custom := 1234.5678;
        Row.Dec5 := 1234.5678;
        Row.Plain := 1234.5678;
        QsObserveRow(Observer, 'a', Row);
        Row.Amt := -0.005;
        Row.UnitAmt := -0.005;
        Row.Custom := -0.005;
        Row.Dec5 := -0.005;
        Row.Plain := -0.005;
        QsObserveRow(Observer, 'b', Row);
        GlobalLanguage(Orig);
#if BC29PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#elif BC28PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#else
        Observer.Expect('a default', '1,234.5678|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.005|-0.005|-0.0|-0.005|-0.005');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure QS_AutoFormatFields_DeDe()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QS Std Fmt Row";
        Orig: Integer;
    begin
        Orig := GlobalLanguage();
        GlobalLanguage(1031);
        Row.Amt := 1234.5678;
        Row.UnitAmt := 1234.5678;
        Row.Custom := 1234.5678;
        Row.Dec5 := 1234.5678;
        Row.Plain := 1234.5678;
        QsObserveRow(Observer, 'a', Row);
        Row.Amt := -0.005;
        Row.UnitAmt := -0.005;
        Row.Custom := -0.005;
        Row.Dec5 := -0.005;
        Row.Plain := -0.005;
        QsObserveRow(Observer, 'b', Row);
        GlobalLanguage(Orig);
#if BC29PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#elif BC28PLUS
        Observer.Expect('a default', '1,234.57|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.57|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.01|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.01|-0.005|-0.0|-0.005|-0.005');
#else
        Observer.Expect('a default', '1,234.5678|1,234.5678|1,234.6|1,234.5678|1,234.5678');
        Observer.Expect('a P22S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a P2S2', '1234.57|1234.57|1234.57|1234.57|1234.57');
        Observer.Expect('a S2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 2', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('a number 9', '1234.5678|1234.5678|1234.6|1234.5678|1234.5678');
        Observer.Expect('b default', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b P22S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b P2S2', '-0.01|-0.01|-0.01|-0.01|-0.01');
        Observer.Expect('b S2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 2', '-0.005|-0.005|-0.0|-0.005|-0.005');
        Observer.Expect('b number 9', '-0.005|-0.005|-0.0|-0.005|-0.005');
#endif
        Observer.Verify();
    end;

    local procedure QsObserveRow(var Observer: Codeunit "Probe Observer"; Prefix: Text; Row: Record "LT QS Std Fmt Row")
    begin
        Observer.Observe(Prefix + ' default', Format(Row.Amt) + '|' + Format(Row.UnitAmt) + '|' + Format(Row.Custom) + '|' + Format(Row.Dec5) + '|' + Format(Row.Plain));
        Observer.Observe(Prefix + ' P22S2', Format(Row.Amt, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.UnitAmt, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.Custom, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.Dec5, 0, '<Precision,2:2><Standard Format,2>') + '|' + Format(Row.Plain, 0, '<Precision,2:2><Standard Format,2>'));
        Observer.Observe(Prefix + ' P2S2', Format(Row.Amt, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.UnitAmt, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.Custom, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.Dec5, 0, '<Precision,2><Standard Format,2>') + '|' + Format(Row.Plain, 0, '<Precision,2><Standard Format,2>'));
        Observer.Observe(Prefix + ' S2', Format(Row.Amt, 0, '<Standard Format,2>') + '|' + Format(Row.UnitAmt, 0, '<Standard Format,2>') + '|' + Format(Row.Custom, 0, '<Standard Format,2>') + '|' + Format(Row.Dec5, 0, '<Standard Format,2>') + '|' + Format(Row.Plain, 0, '<Standard Format,2>'));
        Observer.Observe(Prefix + ' number 2', Format(Row.Amt, 0, 2) + '|' + Format(Row.UnitAmt, 0, 2) + '|' + Format(Row.Custom, 0, 2) + '|' + Format(Row.Dec5, 0, 2) + '|' + Format(Row.Plain, 0, 2));
        Observer.Observe(Prefix + ' number 9', Format(Row.Amt, 0, 9) + '|' + Format(Row.UnitAmt, 0, 9) + '|' + Format(Row.Custom, 0, 9) + '|' + Format(Row.Dec5, 0, 9) + '|' + Format(Row.Plain, 0, 9));
    end;
}
