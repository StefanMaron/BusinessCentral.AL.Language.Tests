// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74063 (BC 29 only), test codeunit 74064
// Facts: a BigInteger assigned to an Option variable (Opt := Big): in range, an ordinal the Option lacks, negative, beyond the Integer range.
//   Whether the assignment raises, and what the variable holds afterwards. An Enum variable gets the same values on BC 29 only (E := Big does not compile on AL 16 and 17: must-not-compile/cases/0451).
// BC versions: 27, 28, 29 by CI

#if BC29PLUS
enum 74063 "LT BE Enum"
{
    Extensible = false;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(7; Seven) { }
}
#endif

codeunit 74064 "LT BigInt To Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Opt: Option Zero,One,Two;
#if BC29PLUS
        E: Enum "LT BE Enum";
#endif
        Shown: Text;

    [TryFunction]
    local procedure SetOpt(Big: BigInteger)
    begin
        Opt := Big;
    end;

#if BC29PLUS
    [TryFunction]
    local procedure SetEnum(Big: BigInteger)
    begin
        E := Big;
    end;

    [TryFunction]
    local procedure ShowEnum()
    begin
        Shown := Format(E) + '|' + Format(E.AsInteger());
    end;

    local procedure ProbeEnum(Name: Text; Value: Text)
    var
        Big: BigInteger;
    begin
        Evaluate(Big, Value);
        Clear(E);
        if SetEnum(Big) then begin
            Obs.Observe(Name + '.set', 'ok');
            if ShowEnum() then
                Obs.Observe(Name + '.val', Shown)
            else
                Obs.ObserveError(Name + '.showerr');
        end else
            Obs.ObserveError(Name + '.err');
    end;

#endif
    [TryFunction]
    local procedure ShowOpt()
    var
        Int: Integer;
    begin
        Int := Opt;
        Shown := Format(Opt) + '|' + Format(Int);
    end;

    local procedure ProbeOpt(Name: Text; Value: Text)
    var
        Big: BigInteger;
    begin
        Evaluate(Big, Value);
        Clear(Opt);
        if SetOpt(Big) then begin
            Obs.Observe(Name + '.set', 'ok');
            if ShowOpt() then
                Obs.Observe(Name + '.val', Shown)
            else
                Obs.ObserveError(Name + '.showerr');
        end else
            Obs.ObserveError(Name + '.err');
    end;

    [Test]
    procedure Option_FromBigInteger_InRangeAndLacking()
    begin
        ProbeOpt('o0', '0');
        ProbeOpt('o1', '1');
        ProbeOpt('o2', '2');
        ProbeOpt('o3', '3');
        ProbeOpt('o7', '7');
        ProbeOpt('o100', '100');
        ProbeOpt('om1', '-1');
        Obs.Expect('o0.set', 'ok');
        Obs.Expect('o0.val', 'Zero|0');
        Obs.Expect('o1.set', 'ok');
        Obs.Expect('o1.val', 'One|1');
        Obs.Expect('o2.set', 'ok');
        Obs.Expect('o2.val', 'Two|2');
        Obs.Expect('o3.set', 'ok');
        Obs.Expect('o3.val', '3|3');
        Obs.Expect('o7.set', 'ok');
        Obs.Expect('o7.val', '7|7');
        Obs.Expect('o100.set', 'ok');
        Obs.Expect('o100.val', '100|100');
        Obs.Expect('om1.set', 'ok');
        Obs.Expect('om1.val', '-1|-1');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT BigInt To Option"(CodeUnit 74064).Option_FromBigInteger_InRangeAndLacking line 9 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;

    [Test]
    procedure Option_FromBigInteger_BeyondInteger()
    begin
        ProbeOpt('imax', '2147483647');
        ProbeOpt('imax1', '2147483648');
        ProbeOpt('u32', '4294967296');
        ProbeOpt('imin', '-2147483648');
        ProbeOpt('imin1', '-2147483649');
        ProbeOpt('lmax', '9223372036854775807');
        Obs.Expect('imax.set', 'ok');
        Obs.Expect('imax.val', '2147483647|2147483647');
        Obs.Expect('imax1.err|text', 'Overflow under conversion of System.Int64 value 2147483648 to System.Int32.');
        Obs.Expect('imax1.err|code', 'ConversionCast');
        Obs.Expect('u32.err|text', 'Overflow under conversion of System.Int64 value 4294967296 to System.Int32.');
        Obs.Expect('u32.err|code', 'ConversionCast');
        Obs.Expect('imin.set', 'ok');
        Obs.Expect('imin.val', '-2147483648|-2147483648');
        Obs.Expect('imin1.err|text', 'Overflow under conversion of System.Int64 value -2147483649 to System.Int32.');
        Obs.Expect('imin1.err|code', 'ConversionCast');
        Obs.Expect('lmax.err|text', 'Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.');
        Obs.Expect('lmax.err|code', 'ConversionCast');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT BigInt To Option"(CodeUnit 74064).Option_FromBigInteger_BeyondInteger line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;

#if BC29PLUS
    [Test]
    procedure Enum_FromBigInteger_InRangeAndLacking()
    begin
        ProbeEnum('e0', '0');
        ProbeEnum('e1', '1');
        ProbeEnum('e2', '2');
        ProbeEnum('e3', '3');
        ProbeEnum('e7', '7');
        ProbeEnum('e100', '100');
        ProbeEnum('em1', '-1');
        Obs.Expect('e0.set', 'ok');
        Obs.Expect('e0.val', 'Zero|0');
        Obs.Expect('e1.set', 'ok');
        Obs.Expect('e1.val', 'One|1');
        Obs.Expect('e2.set', 'ok');
        Obs.Expect('e2.val', 'Two|2');
        Obs.Expect('e3.set', 'ok');
        Obs.Expect('e3.val', '3|3');
        Obs.Expect('e7.set', 'ok');
        Obs.Expect('e7.val', 'Seven|7');
        Obs.Expect('e100.set', 'ok');
        Obs.Expect('e100.val', '100|100');
        Obs.Expect('em1.set', 'ok');
        Obs.Expect('em1.val', '-1|-1');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT BigInt To Option"(CodeUnit 74064).Enum_FromBigInteger_InRangeAndLacking line 9 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;

    [Test]
    procedure Enum_FromBigInteger_BeyondInteger()
    begin
        ProbeEnum('imax', '2147483647');
        ProbeEnum('imax1', '2147483648');
        ProbeEnum('u32', '4294967296');
        ProbeEnum('imin', '-2147483648');
        ProbeEnum('imin1', '-2147483649');
        ProbeEnum('lmax', '9223372036854775807');
        Obs.Expect('imax.set', 'ok');
        Obs.Expect('imax.val', '2147483647|2147483647');
        Obs.Expect('imax1.err|text', 'Overflow under conversion of System.Int64 value 2147483648 to System.Int32.');
        Obs.Expect('imax1.err|code', 'ConversionCast');
        Obs.Expect('u32.err|text', 'Overflow under conversion of System.Int64 value 4294967296 to System.Int32.');
        Obs.Expect('u32.err|code', 'ConversionCast');
        Obs.Expect('imin.set', 'ok');
        Obs.Expect('imin.val', '-2147483648|-2147483648');
        Obs.Expect('imin1.err|text', 'Overflow under conversion of System.Int64 value -2147483649 to System.Int32.');
        Obs.Expect('imin1.err|code', 'ConversionCast');
        Obs.Expect('lmax.err|text', 'Overflow under conversion of System.Int64 value 9223372036854775807 to System.Int32.');
        Obs.Expect('lmax.err|code', 'ConversionCast');
        Obs.Expect('
AL Callstack:
"Probe Observer State"(CodeUnit 69163).Raise line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0
"Probe Observer"(CodeUnit 69160).Finish line 6 - AL Language Coverage Tests by AL Language version 1.0.0.0
"LT BigInt To Option"(CodeUnit 74064).Enum_FromBigInteger_BeyondInteger line 8 - AL Language Coverage Tests by AL Language version 1.0.0.0

', '');
        Obs.Verify();
    end;
#endif
}
