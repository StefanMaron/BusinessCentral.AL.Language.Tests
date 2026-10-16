// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74405
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: JsonObject.Replace(existing key, value) per value type
// BC versions: 29 (27 and 28 by CI)

codeunit 74405 "LT P88 Object Replace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rec(Name: Text; Ok: Boolean; Txt: Text)
    begin
        Observer.Observe(Name + '_ok', Format(Ok));
        if Ok then
            Observer.Observe(Name + '_text', Txt)
        else
            Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure DoBoolean(var O: JsonObject)
    var
        Bo: Boolean;
    begin
        Bo := true;
        O.Replace('b', Bo);
    end;

    [TryFunction]
    local procedure DoByte(var O: JsonObject)
    var
        By: Byte;
    begin
        By := 200;
        O.Replace('b', By);
    end;

    [TryFunction]
    local procedure DoChar(var O: JsonObject)
    var
        Ch: Char;
    begin
        Ch := 65;
        O.Replace('b', Ch);
    end;

    [TryFunction]
    local procedure DoDate(var O: JsonObject)
    var
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        O.Replace('b', D);
    end;

    [TryFunction]
    local procedure DoTime(var O: JsonObject)
    var
        Ti: Time;
    begin
        Ti := 143015T;
        O.Replace('b', Ti);
    end;

    [TryFunction]
    local procedure DoDateTime(var O: JsonObject)
    var
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 3, 2024), 143015T);
        O.Replace('b', DT);
    end;

    [TryFunction]
    local procedure DoDuration(var O: JsonObject)
    var
        Du: Duration;
    begin
        Du := 90061001;
        O.Replace('b', Du);
    end;

    [TryFunction]
    local procedure DoDecimal(var O: JsonObject)
    var
        Dc: Decimal;
    begin
        Dc := 12.345;
        O.Replace('b', Dc);
    end;

    [TryFunction]
    local procedure DoInteger(var O: JsonObject)
    var
        I: Integer;
    begin
        I := 42;
        O.Replace('b', I);
    end;

    [TryFunction]
    local procedure DoBigInteger(var O: JsonObject)
    var
        Bi: BigInteger;
    begin
        Bi := 2147483647; Bi := Bi * 3;
        O.Replace('b', Bi);
    end;

    [TryFunction]
    local procedure DoOption(var O: JsonObject)
    var
        Op: Option Alpha,Beta,Gamma;
    begin
        Op := Op::Beta;
        O.Replace('b', Op);
    end;

    [TryFunction]
    local procedure DoText(var O: JsonObject)
    var
        Tx: Text;
    begin
        Tx := 'he said "hi" \ / end';
        O.Replace('b', Tx);
    end;

    [TryFunction]
    local procedure DoJsonToken(var O: JsonObject)
    var
        Tk: JsonToken;
    begin
        Tk.ReadFrom('{"k":[1,2]}');
        O.Replace('b', Tk);
    end;

    [TryFunction]
    local procedure DoJsonArray(var O: JsonObject)
    var
        Ja: JsonArray;
    begin
        Ja.ReadFrom('[1,"two"]');
        O.Replace('b', Ja);
    end;

    [TryFunction]
    local procedure DoJsonObject(var O: JsonObject)
    var
        Jo: JsonObject;
    begin
        Jo.ReadFrom('{"k":"v"}');
        O.Replace('b', Jo);
    end;

    [TryFunction]
    local procedure DoJsonValue(var O: JsonObject)
    var
        Jv: JsonValue;
    begin
        Jv.SetValue(7);
        O.Replace('b', Jv);
    end;

    [Test]
    procedure ReplaceO_Part1()
    var
        O: JsonObject;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoBoolean(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Boolean', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoByte(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Byte', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoChar(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Char', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoDate(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Date', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoTime(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Time', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoDateTime(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_DateTime', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoDuration(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Duration', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoDecimal(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Decimal', Ok, Txt);
        Observer.Finish();
    end;

    [Test]
    procedure ReplaceO_Part2()
    var
        O: JsonObject;
        Txt: Text;
        Ok: Boolean;
    begin
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoInteger(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Integer', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoBigInteger(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_BigInteger', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoOption(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Option', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoText(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_Text', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoJsonToken(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_JsonToken', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoJsonArray(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_JsonArray', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoJsonObject(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_JsonObject', Ok, Txt);
        Clear(O);
        O.Add('a', 1);
        O.Add('b', 2);
        Ok := DoJsonValue(O);
        O.WriteTo(Txt);
        Rec('ReplaceO_JsonValue', Ok, Txt);
        Observer.Finish();
    end;
}
