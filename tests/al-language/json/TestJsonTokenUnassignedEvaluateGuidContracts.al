// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsontoken/jsontoken-data-type
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68992
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - a JsonToken variable nobody assigned acts as a JSON null value: IsObject and IsArray are false, IsValue is true, WriteTo gives
//    null, AsValue works (IsNull true), AsObject and AsArray raise "Unable to convert from
//    Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject." (NavJsonArray for AsArray) /
//    Conversion, and SelectToken answers false;
//  - Evaluate into a Guid takes the braced, the plain and the 32 digit forms; a text that is not a Guid and the empty text answer
//    false and leave the Guid as it was; as a statement the nonsense raises "Invalid format of GUID string. The correct format of
//    the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits." / InvalidGuidFormat.
// BC versions: 27.5

codeunit 68992 "Probe JsonToken Unassigned"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure UnassignedJsonToken_ActsAsANull()
    var
        Tok: JsonToken;
        Obj: JsonObject;
        Arr: JsonArray;
        JsonVal: JsonValue;
        Text: Text;
    begin
        Assert.IsFalse(Tok.IsObject(), 'IsObject');
        Assert.IsFalse(Tok.IsArray(), 'IsArray');
        Assert.IsTrue(Tok.IsValue(), 'IsValue');
        Tok.WriteTo(Text);
        Assert.AreEqual('null', Text, 'WriteTo');
        JsonVal := Tok.AsValue();
        Assert.IsTrue(JsonVal.IsNull(), 'AsValue.IsNull');
        Assert.IsFalse(Tok.SelectToken('a', Tok), 'SelectToken');

        asserterror Obj := Tok.AsObject();
        Assert.AreEqual('Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonObject.', GetLastErrorText(), 'AsObject');
        Assert.AreEqual('Conversion', GetLastErrorCode(), 'code');
        asserterror Arr := Tok.AsArray();
        Assert.AreEqual('Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonArray.', GetLastErrorText(), 'AsArray');
    end;

    [Test]
    procedure EvaluateGuid_Forms_AndFailures()
    var
        Value: Guid;
        Known: Guid;
    begin
        Known := '{11111111-2222-3333-4444-555555555555}';

        Assert.IsTrue(Evaluate(Value, '{11111111-2222-3333-4444-555555555555}'), 'braced');
        Assert.AreEqual(Known, Value, 'braced value');
        Clear(Value);
        Assert.IsTrue(Evaluate(Value, '11111111-2222-3333-4444-555555555555'), 'plain');
        Assert.AreEqual(Known, Value, 'plain value');
        Clear(Value);
        Assert.IsTrue(Evaluate(Value, '11111111222233334444555555555555'), '32 digits');
        Assert.AreEqual(Known, Value, '32 digits value');

        Assert.IsFalse(Evaluate(Value, 'nonsense'), 'nonsense');
        Assert.AreEqual(Known, Value, 'unchanged after nonsense');
        Assert.IsFalse(Evaluate(Value, ''), 'empty');
        Assert.AreEqual(Known, Value, 'unchanged after empty');

        asserterror Evaluate(Value, 'nonsense');
        Assert.AreEqual('Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.', GetLastErrorText(), 'text');
        Assert.AreEqual('InvalidGuidFormat', GetLastErrorCode(), 'code');
    end;
}
