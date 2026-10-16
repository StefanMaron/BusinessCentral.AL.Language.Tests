// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74412
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: how Date, Time, DateTime, Duration, BigInteger, Option, Char, Byte read back from JSON as text and as typed values
// BC versions: 29 (27 and 28 by CI)

codeunit 74412 "LT P88 DateTime Readback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure TimeMs(T: Time; Ms: Integer): Time
    begin
        exit(T + Ms);
    end;

    local procedure Fmt(V: Variant): Text
    begin
        exit(Format(V, 0, 9));
    end;

    [TryFunction]
    local procedure TryAsDate(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsDate());
    end;

    [TryFunction]
    local procedure TryAsTime(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsTime());
    end;

    [TryFunction]
    local procedure TryAsDateTime(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsDateTime());
    end;

    [TryFunction]
    local procedure TryAsDuration(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsDuration());
    end;

    [TryFunction]
    local procedure TryAsBigInt(V: JsonValue; var R: Text)
    begin
        R := Fmt(V.AsBigInteger());
    end;

    local procedure Res(Name: Text; Ok: Boolean; R: Text)
    begin
        if Ok then
            Observer.Observe(Name, R)
        else
            Observer.ObserveError(Name);
    end;

    local procedure Back(Name: Text; V: JsonValue)
    var
        Txt: Text;
        R: Text;
    begin
        V.WriteTo(Txt);
        Observer.Observe(Name + '_json', Txt);
        Observer.Observe(Name + '_astext', V.AsText());
        Res(Name + '_asdate', TryAsDate(V, R), R);
        Res(Name + '_astime', TryAsTime(V, R), R);
        Res(Name + '_asdatetime', TryAsDateTime(V, R), R);
    end;

    [Test]
    procedure Date_Readback()
    var
        V: JsonValue;
    begin
        V.SetValue(DMY2Date(15, 3, 2024));
        Back('date', V);
        V.SetValue(DMY2Date(1, 1, 1753));
        Back('date_min', V);
        V.SetValue(DMY2Date(31, 12, 9999));
        Back('date_max', V);
        V.SetValue(0D);
        Back('date_blank', V);
        Observer.Finish();
    end;

    [Test]
    procedure Time_Readback()
    var
        V: JsonValue;
    begin
        V.SetValue(TimeMs(143015T, 123));
        Back('time', V);
        V.SetValue(0T);
        Back('time_blank', V);
        V.SetValue(000000T);
        Back('time_midnight', V);
        V.SetValue(TimeMs(235959T, 999));
        Back('time_max', V);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Readback()
    var
        V: JsonValue;
    begin
        V.SetValue(CreateDateTime(DMY2Date(15, 3, 2024), TimeMs(143015T, 123)));
        Back('datetime', V);
        V.SetValue(CreateDateTime(DMY2Date(15, 3, 2024), 0T));
        Back('datetime_midnight', V);
        V.SetValue(0DT);
        Back('datetime_blank', V);
        V.SetValue(CreateDateTime(DMY2Date(1, 1, 1753), 000001T));
        Back('datetime_min', V);
        Observer.Finish();
    end;

    [Test]
    procedure TextToTyped()
    var
        V: JsonValue;
        R: Text;
    begin
        V.SetValue('2024-03-15');
        Res('text_date_asdate', TryAsDate(V, R), R);
        V.SetValue('2024-03-15T14:30:15Z');
        Res('text_iso_asdatetime', TryAsDateTime(V, R), R);
        Res('text_iso_asdate', TryAsDate(V, R), R);
        V.SetValue('14:30:15');
        Res('text_time_astime', TryAsTime(V, R), R);
        V.SetValue('15.03.2024');
        Res('text_localdate_asdate', TryAsDate(V, R), R);
        V.SetValue('garbage');
        Res('text_garbage_asdate', TryAsDate(V, R), R);
        Res('text_garbage_astime', TryAsTime(V, R), R);
        Res('text_garbage_asdatetime', TryAsDateTime(V, R), R);
        Observer.Finish();
    end;

    [Test]
    procedure Duration_BigInteger_Readback()
    var
        V: JsonValue;
        Bi: BigInteger;
        R: Text;
        Txt: Text;
    begin
        V.SetValue(90061001);
        V.WriteTo(Txt);
        Observer.Observe('duration_json', Txt);
        Observer.Observe('duration_astext', V.AsText());
        Res('duration_asduration', TryAsDuration(V, R), R);
        Res('duration_asbigint', TryAsBigInt(V, R), R);
        Bi := 2147483647;
        Bi := Bi * 3;
        V.SetValue(Bi);
        V.WriteTo(Txt);
        Observer.Observe('bigint_json', Txt);
        Observer.Observe('bigint_astext', V.AsText());
        Res('bigint_asbigint', TryAsBigInt(V, R), R);
        Observer.Observe('bigint_asdecimal', Format(V.AsDecimal(), 0, 9));
        Bi := -Bi;
        V.SetValue(Bi);
        Observer.Observe('negbigint_astext', V.AsText());
        Observer.Finish();
    end;

    [Test]
    procedure Char_Byte_Option_Readback()
    var
        V: JsonValue;
        Ch: Char;
        By: Byte;
        Op: Option Alpha,Beta,Gamma;
        Txt: Text;
    begin
        Ch := 65;
        V.SetValue(Ch);
        V.WriteTo(Txt);
        Observer.Observe('char_json', Txt);
        Observer.Observe('char_astext', V.AsText());
        By := 200;
        V.SetValue(By);
        V.WriteTo(Txt);
        Observer.Observe('byte_json', Txt);
        Observer.Observe('byte_asinteger', Format(V.AsInteger()));
        Op := Op::Gamma;
        V.SetValue(Op);
        V.WriteTo(Txt);
        Observer.Observe('option_json', Txt);
        Observer.Observe('option_astext', V.AsText());
        Observer.Observe('option_asinteger', Format(V.AsInteger()));
        V.SetValue(true);
        Observer.Observe('bool_astext', V.AsText());
        Observer.Observe('bool_asboolean', Format(V.AsBoolean()));
        Observer.Finish();
    end;
}
