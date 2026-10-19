// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/char/char-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained table 83756, reports 83757 and 83759, report extension 83758, codeunits 83760 and 83761
// Probe: writer BV (2026-10-19, Windows check 3 item BB, from writer BB's probe of corpus issue 653 item 2). The report values were measured on Windows BC 27.5
// and 29.0 (official containers) and on the Linux tiers; every literal asserted below is what those tiers produced.
// Facts: a Char VARIABLE passed to a report procedure Bump(A: Integer) fails with 'Unable to convert from System.Char to System.Int32.' (code Conversion),
// caught by a TryFunction, both when a report extension adds an overload Bump(A: Text) and on a report without an extension (both measured on Windows too).
// A procedure Bump(A: Integer) of ANOTHER codeunit fails the same way (measured on the Linux tiers only, queued for the Windows nightly); a local procedure of
// the calling codeunit is the control.
// BC versions: 27, 28, 29

table 83756 "LT BV Char Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 83757 "LT BV Char Base Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset { dataitem(Row; "LT BV Char Row") { } }

    procedure Bump(A: Integer): Text
    begin
        exit('base integer ' + Format(A));
    end;
}

reportextension 83758 "LT BV Char Base Report Ext" extends "LT BV Char Base Report"
{
    procedure Bump(A: Text): Text
    begin
        exit('extension text ' + A);
    end;
}

report 83759 "LT BV Char Plain Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset { dataitem(Row; "LT BV Char Row") { } }

    procedure Bump(A: Integer): Text
    begin
        exit('plain integer ' + Format(A));
    end;
}

codeunit 83760 "LT BV Char Target"
{
    procedure Bump(A: Integer): Text
    begin
        exit('codeunit integer ' + Format(A));
    end;
}

codeunit 83761 "LT BV Report Char Arg"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryBumpExt(var R: Report "LT BV Char Base Report"; Ch: Char; var Result: Text)
    begin
        Result := R.Bump(Ch);
    end;

    [TryFunction]
    local procedure TryBumpPlain(var R: Report "LT BV Char Plain Report"; Ch: Char; var Result: Text)
    begin
        Result := R.Bump(Ch);
    end;

    [Test]
    procedure ReportWithExtension_CharVariableToIntegerOverload()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT BV Char Base Report";
        Ch: Char;
        Result: Text;
    begin
        Ch := 'q';
        Result := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryBumpExt(R, Ch, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('char var');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('char var|text', 'Unable to convert from System.Char to System.Int32.');
        Observer.Expect('char var|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure PlainReport_CharVariableToInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Report "LT BV Char Plain Report";
        Ch: Char;
        Result: Text;
    begin
        Ch := 'q';
        Result := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryBumpPlain(R, Ch, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('char var');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('char var|text', 'Unable to convert from System.Char to System.Int32.');
        Observer.Expect('char var|code', 'Conversion');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryBumpCodeunit(var Target: Codeunit "LT BV Char Target"; Ch: Char; var Result: Text)
    begin
        Result := Target.Bump(Ch);
    end;

    local procedure LocalBump(A: Integer): Text
    begin
        exit('local integer ' + Format(A));
    end;

    [Test]
    procedure OtherCodeunit_CharVariableToInteger()
    var
        Observer: Codeunit "Probe Observer";
        Target: Codeunit "LT BV Char Target";
        Ch: Char;
        Result: Text;
    begin
        Ch := 'q';
        Result := '-';
        ClearLastError();
        Observer.Observe('ok', Format(TryBumpCodeunit(Target, Ch, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('char var');
        Observer.Expect('ok', 'No');
        Observer.Expect('result', '-');
        Observer.Expect('char var|text', 'Unable to convert from System.Char to System.Int32.');
        Observer.Expect('char var|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure LocalProcedure_CharVariableToInteger_Control()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
    begin
        Ch := 'q';
        Observer.Observe('result', LocalBump(Ch));
        Observer.Expect('result', 'local integer 113');
        Observer.Verify();
    end;
}
