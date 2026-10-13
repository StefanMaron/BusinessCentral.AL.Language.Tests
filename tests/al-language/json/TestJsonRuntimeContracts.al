// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier (en-US, UTC); every literal below is what
// that tier produced. Other BC versions were not measured.
//
// Pins what WriteTo writes (compact, keys in insertion order, the text of each value type),
// what ReadFrom does with bad input, how dates and numbers are read back, the sharing rules
// of Add, the Path of a token, and the text and code of each JSON error.
// BC versions: 27.5

codeunit 68127 "Probe Json Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure JsonObject_WriteTo_IsCompactAndKeepsInsertionOrder()
    var
        Root: JsonObject;
        Inner: JsonObject;
        Items: JsonArray;
        Result: Text;
    begin
        Initialize();
        Root.Add('b', 1);
        Root.Add('a', 'x"y\z/');
        Root.Add('n', 1.50);
        Root.Add('t', true);
        Root.Add('arr', Items);
        Items.Add(1);
        Items.Add('s');
        Items.Add(Inner);
        Inner.Add('k', 'v');

        Root.WriteTo(Result);

        Assert.AreEqual('{"b":1,"a":"x\"y\\z/","n":1.50,"t":true,"arr":[1,"s",{"k":"v"}]}', Result, 'compact text');
    end;

    [Test]
    procedure JsonObject_WriteTo_TextOfDateTimeDurationBigIntegerAndDecimal()
    var
        Root: JsonObject;
        BigValue: BigInteger;
        Result: Text;
    begin
        Initialize();
        Evaluate(BigValue, '12345678901234');
        Root.Add('d', DMY2Date(5, 3, 2024));
        Root.Add('t', 143005T);
        Root.Add('dt', CreateDateTime(DMY2Date(5, 3, 2024), 143005T));
        Root.Add('du', 90061001);
        Root.Add('big', BigValue);
        Root.Add('dec', 0.1);
        Root.Add('neg', -0.0000001);

        Root.WriteTo(Result);

        Assert.AreEqual('{"d":"2024-03-05","t":"14:30:05","dt":"2024-03-05T14:30:05.0000000Z","du":90061001,"big":12345678901234,"dec":0.1,"neg":-0.0000001}', Result, 'values');
    end;

    [Test]
    procedure JsonObject_WriteTo_GuidIsBracedUpperCase()
    var
        Root: JsonObject;
        Id: Guid;
        Result: Text;
    begin
        Initialize();
        Evaluate(Id, '{ce0998b5-7f48-47e4-b7fb-c538e9b4b03d}');
        Root.Add('g', Id);

        Root.WriteTo(Result);

        Assert.AreEqual('{"g":"{CE0998B5-7F48-47E4-B7FB-C538E9B4B03D}"}', Result, 'guid');
    end;

    [Test]
    procedure JsonObject_ReadFrom_NumbersKeepTheirWrittenForm()
    var
        Root: JsonObject;
        Result: Text;
    begin
        Initialize();

        Assert.IsTrue(Root.ReadFrom('{"a":1.0,"b":1e2,"c":12345678901234567890,"d":0.1,"e":"xä"}'), 'read');
        Root.WriteTo(Result);

        Assert.AreEqual('{"a":1.0,"b":100.0,"c":12345678901234567890,"d":0.1,"e":"xä"}', Result, 'round trip');

        Assert.IsTrue(Root.ReadFrom(' {"a" : [ 1 , 2 ] } '), 'white space is accepted');
        Root.WriteTo(Result);
        Assert.AreEqual('{"a":[1,2]}', Result, 'white space is dropped');
    end;

    [Test]
    procedure JsonObject_ReadFrom_InvalidJson_ReturnsFalse_AndStatementFormThrows()
    var
        Root: JsonObject;
        Items: JsonArray;
    begin
        Initialize();

        Assert.IsFalse(Root.ReadFrom('{bad'), 'invalid JSON');
        Assert.IsFalse(Root.ReadFrom('[1,2]'), 'an array into a JsonObject');
        Assert.IsFalse(Items.ReadFrom('{"a":1}'), 'an object into a JsonArray');

        asserterror Root.ReadFrom('{bad');

        Assert.AreEqual('The data does not represent a valid JSON token.', GetLastErrorText(), 'text');
        Assert.AreEqual('InvalidJsonData', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure JsonObject_Errors_TextAndCode()
    var
        Root: JsonObject;
        Items: JsonArray;
        Token: JsonToken;
        Value: JsonValue;
        Nested: JsonObject;
        Number: Integer;
        Content: Text;
    begin
        Initialize();
        Root.ReadFrom('{"a":1,"s":"x"}');
        Items.ReadFrom('[1]');

        asserterror Content := Root.GetText('zz');
        Assert.AreEqual('There is no property with the ''zz'' key on the JSON object.', GetLastErrorText(), 'missing key');
        Assert.AreEqual('JsonPropertyNotFound', GetLastErrorCode(), 'missing key code');

        asserterror Items.Get(5, Token);
        Assert.AreEqual('Index out of bounds.', GetLastErrorText(), 'index');
        Assert.AreEqual('IndexOutOfBounds', GetLastErrorCode(), 'index code');

        asserterror Value := Root.AsToken().AsValue();
        Assert.AreEqual('Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonToken to Microsoft.Dynamics.Nav.Runtime.NavJsonValue.', GetLastErrorText(), 'AsValue on an object');
        Assert.AreEqual('Conversion', GetLastErrorCode(), 'AsValue code');

        asserterror Root.Add('a', 2);
        Assert.AreEqual('The JSON object already contains the key ''a''.', GetLastErrorText(), 'duplicate key');
        Assert.AreEqual('DuplicateJsonProperty', GetLastErrorCode(), 'duplicate key code');

        asserterror Nested := Root.GetObject('a');
        Assert.AreEqual('Unable to convert from Integer to Object.', GetLastErrorText(), 'GetObject on a number');
        Assert.AreEqual('Conversion', GetLastErrorCode(), 'GetObject code');

        asserterror Number := Root.GetInteger('s');
        Assert.AreEqual('Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to System.Int32.', GetLastErrorText(), 'GetInteger on a string');
        Assert.AreEqual('Conversion', GetLastErrorCode(), 'GetInteger code');
    end;

    [Test]
    procedure JsonObject_Get_MissingKey_ReturnsFalse()
    var
        Root: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Root.ReadFrom('{"a":1}');

        Assert.IsFalse(Root.Get('missing', Token), 'Get of a missing key');
    end;

    [Test]
    procedure JsonToken_Path_IsDottedWithIndexes()
    var
        Root: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Root.ReadFrom('{"a":{"b":[0,{"c":1}]}}');

        Root.SelectToken('a.b[1].c', Token);
        Assert.AreEqual('a.b[1].c', Token.Path(), 'deep token');

        Root.Get('a', Token);
        Token.AsObject().Get('b', Token);
        Assert.AreEqual('a.b', Token.Path(), 'array token');
    end;

    [Test]
    procedure JsonToken_ReadAsDateTimeTimeDuration()
    // CLAIM: a date-time text without an offset is read as UTC; an offset is converted to UTC; a number read as a Duration is milliseconds.
    var
        Root: JsonObject;
        Token: JsonToken;
    begin
        Initialize();
        Root.ReadFrom('{"d":"2024-03-05","dt":"2024-03-05T14:30:05","dtz":"2024-03-05T14:30:05+02:00","dts":"2024-03-05T14:30:05Z","t":"14:30:05","du":5000}');

        Root.Get('d', Token);
        Assert.AreEqual('2024-03-05', Format(Token.AsValue().AsDate(), 0, 9), 'date');
        Root.Get('dt', Token);
        Assert.AreEqual('2024-03-05T14:30:05Z', Format(Token.AsValue().AsDateTime(), 0, 9), 'no offset');
        Root.Get('dtz', Token);
        Assert.AreEqual('2024-03-05T12:30:05Z', Format(Token.AsValue().AsDateTime(), 0, 9), 'with an offset');
        Root.Get('dts', Token);
        Assert.AreEqual('2024-03-05T14:30:05Z', Format(Token.AsValue().AsDateTime(), 0, 9), 'with Z');
        Root.Get('t', Token);
        Assert.AreEqual('14:30:05', Format(Token.AsValue().AsTime(), 0, 9), 'time');
        Root.Get('du', Token);
        Assert.AreEqual('P0DT0H0M5.0S', Format(Token.AsValue().AsDuration(), 0, 9), 'duration');
    end;

    [Test]
    procedure JsonObject_Add_FreeObjectIsShared_ObjectWithAParentIsCopied()
    var
        Child: JsonObject;
        FirstParent: JsonObject;
        List: JsonArray;
        Result: Text;
    begin
        Initialize();
        Child.ReadFrom('{"a":1}');

        FirstParent.Add('o', Child);
        Child.Add('b', 2);
        FirstParent.WriteTo(Result);
        Assert.AreEqual('{"o":{"a":1,"b":2}}', Result, 'a change after Add of a free object is visible through the parent');

        List.Add(Child);
        Child.Add('c', 3);
        List.WriteTo(Result);
        Assert.AreEqual('[{"a":1,"b":2}]', Result, 'adding an object that already has a parent copies it');
        FirstParent.WriteTo(Result);
        Assert.AreEqual('{"o":{"a":1,"b":2,"c":3}}', Result, 'the first parent still sees the original');
    end;

    [Test]
    procedure JsonObject_Yaml_RoundTripsOnThisTier()
    // CLAIM: on this container WriteToYaml and ReadFromYaml work. (A Cloud tier may differ; tests that pin an error there are in session/TestFinalCoverage.al.)
    var
        Root: JsonObject;
        Yaml: Text;
        LineFeed: Text[1];
    begin
        Initialize();
        LineFeed[1] := 10;
        Root.ReadFrom('{"a":1}');

        Root.WriteToYaml(Yaml);
        Assert.AreEqual('a: 1' + LineFeed, Yaml, 'yaml text');
        Root.ReadFromYaml('a: 1');
    end;

    [Test]
    procedure JsonValue_Null_AsTextThrows()
    var
        Root: JsonObject;
        Token: JsonToken;
        Content: Text;
    begin
        Initialize();
        Root.ReadFrom('{"a":null}');
        Root.Get('a', Token);

        Assert.IsTrue(Token.IsValue(), 'null is a value token');
        Assert.IsTrue(Token.AsValue().IsNull(), 'and it is null');

        asserterror Content := Token.AsValue().AsText();
        Assert.AreEqual('Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.NavText.', GetLastErrorText(), 'text');
        Assert.AreEqual('Conversion', GetLastErrorCode(), 'code');
    end;
}
