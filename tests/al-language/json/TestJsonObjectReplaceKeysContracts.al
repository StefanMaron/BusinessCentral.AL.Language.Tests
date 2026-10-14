// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-replace-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-keys-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68940
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins JsonObject.Replace and JsonObject.Keys:
//  - Keys() lists the keys in insertion order (also after Remove and a later Add of the same key, which goes last);
//    an empty object gives an empty list; the list is a copy (a later Add does not change it); keys are case sensitive
//    ("b" and "B" are two keys).
//  - Replace(Key, Value) answers true and REMOVES the key and adds it again at the END: after Add a, b, c and Replace b, WriteTo
//    gives {"a":1,"c":3,"b":20} and Keys() a,c,b. The new value may be of another type, a JsonValue or a JsonToken.
//    A JsonObject value is shared, not copied: a later Add on it shows in the object.
//  - Replace of a missing key answers false when the result is used, and raises "There is no property with the 'zz' key
//    on the JSON object." / JsonPropertyNotFound as a statement.
// BC versions: 27.5

codeunit 68940 "Probe Json Replace Keys"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Text(Obj: JsonObject): Text
    var
        Result: Text;
    begin
        Obj.WriteTo(Result);
        exit(Result);
    end;

    local procedure KeysText(Obj: JsonObject): Text
    var
        KeyName: Text;
        Result: Text;
    begin
        foreach KeyName in Obj.Keys() do
            Result += KeyName + ',';
        exit(Result);
    end;

    [Test]
    procedure Replace_MovesTheKeyToTheEnd_AndTakesAnyValue()
    var
        Obj: JsonObject;
        Child: JsonObject;
        JsonVal: JsonValue;
        Tok: JsonToken;
    begin
        Obj.Add('a', 1);
        Obj.Add('b', 2);
        Obj.Add('c', 3);

        Assert.IsTrue(Obj.Replace('b', 20), 'Replace as a value');
        Assert.AreEqual('{"a":1,"c":3,"b":20}', Text(Obj), 'json');
        Assert.AreEqual('a,c,b,', KeysText(Obj), 'keys');
        Obj.Get('b', Tok);
        Assert.AreEqual(20, Tok.AsValue().AsInteger(), 'Get');

        Obj.Replace('a', 'text now');
        Assert.AreEqual('{"c":3,"b":20,"a":"text now"}', Text(Obj), 'another type');

        Child.Add('x', 1);
        Obj.Replace('c', Child);
        Assert.AreEqual('{"b":20,"a":"text now","c":{"x":1}}', Text(Obj), 'an object');
        Child.Add('y', 2);
        Assert.AreEqual('{"b":20,"a":"text now","c":{"x":1,"y":2}}', Text(Obj), 'the object is shared, not copied');

        JsonVal.SetValue(true);
        Obj.Replace('a', JsonVal);
        Assert.AreEqual('{"b":20,"c":{"x":1,"y":2},"a":true}', Text(Obj), 'a JsonValue');

        Tok := Child.AsToken();
        Obj.Replace('b', Tok);
        Assert.AreEqual('{"c":{"x":1,"y":2},"a":true,"b":{"x":1,"y":2}}', Text(Obj), 'a JsonToken');
    end;

    [Test]
    procedure Replace_KeysAreCaseSensitive()
    var
        Obj: JsonObject;
    begin
        Obj.Add('b', 1);
        Obj.Add('B', 5);

        Assert.AreEqual('b,B,', KeysText(Obj), 'two keys');
        Assert.IsTrue(Obj.Replace('B', 6), 'Replace B');
        Assert.AreEqual('{"b":1,"B":6}', Text(Obj), 'only B changed');
    end;

    [Test]
    procedure Replace_MissingKey_FalseAsAValue_ErrorAsAStatement()
    var
        Obj: JsonObject;
    begin
        Obj.Add('a', 1);

        Assert.IsFalse(Obj.Replace('zz', 1), 'as a value');
        Assert.AreEqual('{"a":1}', Text(Obj), 'unchanged');

        asserterror Obj.Replace('zz', 1);
        Assert.AreEqual('There is no property with the ''zz'' key on the JSON object.', GetLastErrorText(), 'text');
        Assert.AreEqual('JsonPropertyNotFound', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure Keys_InsertionOrder_AfterRemoveAndAdd_AndTheListIsACopy()
    var
        Obj: JsonObject;
        Listed: List of [Text];
    begin
        Assert.AreEqual('', KeysText(Obj), 'empty object');

        Obj.Add('b', 1);
        Obj.Add('a', 1);
        Obj.Add('c', 1);
        Assert.AreEqual('b,a,c,', KeysText(Obj), 'insertion order');
        Obj.Remove('a');
        Assert.AreEqual('b,c,', KeysText(Obj), 'after Remove');
        Obj.Add('a', 9);
        Assert.AreEqual('b,c,a,', KeysText(Obj), 'a re-added key goes last');

        Listed := Obj.Keys();
        Obj.Add('d', 1);
        Assert.AreEqual(3, Listed.Count(), 'the list is a copy');
        Assert.AreEqual(4, Obj.Keys().Count(), 'a new call sees the new key');

        Obj.Replace('b', 99);
        Assert.AreEqual('c,a,d,b,', KeysText(Obj), 'after Replace of the first key');
    end;
}
