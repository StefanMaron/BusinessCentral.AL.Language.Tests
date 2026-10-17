// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/option/option-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own enum 74063, test codeunit 74064
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a BigInteger assigned to an Option variable and to an Enum variable (Opt := Big, E := Big): in range, an ordinal the Option or Enum lacks,
//   negative, beyond the Integer range. Whether the assignment raises, and what the variable holds afterwards.
// BC versions: 27, 28, 29 by CI

enum 74063 "LT BE Enum"
{
    Extensible = false;

    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(7; Seven) { }
}

codeunit 74064 "LT BigInt To Enum Option"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";
        Opt: Option Zero,One,Two;
        E: Enum "LT BE Enum";
        Shown: Text;

    [TryFunction]
    local procedure SetOpt(Big: BigInteger)
    begin
        Opt := Big;
    end;

    [TryFunction]
    local procedure SetEnum(Big: BigInteger)
    begin
        E := Big;
    end;

    [TryFunction]
    local procedure ShowOpt()
    var
        Int: Integer;
    begin
        Int := Opt;
        Shown := Format(Opt) + '|' + Format(Int);
    end;

    [TryFunction]
    local procedure ShowEnum()
    begin
        Shown := Format(E) + '|' + Format(E.AsInteger());
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
        Obs.Finish();
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
        Obs.Finish();
    end;

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
        Obs.Finish();
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
        Obs.Finish();
    end;
}
