// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-get-started-call-dotnet-from-al
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), and only with an AL compiler of version 18.0 or newer: AL 16.x and 17.x (what
// the CI picks for BC 27 and 28) fail with AL0451 "An assembly named 'mscorlib, PublicKeyToken=null' could not be found in the assembly probing
// paths ''" for the dotnet block below. The app is therefore not in the CI test_app_dirs (see its app.json); run it with a newer compiler.
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app; self-contained codeunit 61400
// Probe: written against a real BC 27.5 service tier started by bc-linux; every literal below is what that tier
// produced. Other BC versions and other hosts were not measured.
//
// Pins how AL sees the values of DotNet calls (ADR-024):
//  - KIND: a CLR int and short read as Integer, long as BigInteger, byte as Byte, char as Char, float, double and decimal as
//    Decimal, bool as Boolean, string as Text, a TimeSpan as Duration, a Guid as Guid, a DateTime as DateTime; an enum value
//    stays a DotNet object (Format gives the member name); a null string is an empty Variant (neither Text nor DotNet).
//  - Expressions: Count - 1 and Length / 2 on an int property work as Integer arithmetic (also as a for bound);
//    a string property compared with a Text literal is compared CASE SENSITIVELY ('https' = 'HTTPS' is false).
//  - A null string result: = '' is true, Format gives '' and + 'x' gives 'x'. StrLen(null string) and Format(null object)
//    raise an UNCATCHABLE "Unexpected CLR exception thrown.: System.ArgumentNullException" (not testable here).
//  - Format of a DotNet object is its ToString(): a Type reads System.Text.StringBuilder, an enum its member name, a
//    StringBuilder its content; Format(x, 0, 2) and Format(x, 0, 0) give the same text. IsNull is true for an unassigned object.
//  - Enum operators: = and <> between two enum values compare them; + adds them as numbers (NumberStyles.Number 111 +
//    AllowCurrencySymbol 256 is 367); = between two objects of a class, or of different DotNet types, does not compile (AL0175).
//  - foreach: over a string[] (Text elements), an ArrayList of ints (Integer or Variant elements; a Text loop variable raises
//    "Invalid Conversion. Source: Int32, Destination: NavText." / Argument; a Date variable over text elements "Unable to convert
//    from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime." / Conversion), a Queue (not consumed) and a string (chars);
//    a null collection raises "A DotNet variable has not been instantiated. Attempting to call System.Collections.ArrayList.GetEnumerator
//    in CodeUnit <name>: <procedure>" / DotNetVariableNotCreated; a collection modified in the loop raises "A call to
//    System.Collections.ArrayList+ArrayListEnumeratorSimple.MoveNext failed with this message: Collection was modified; enumeration
//    operation may not execute." / DotNetInvoke:InvalidOperation after the first element.
//  - CopyStream with a MemoryStream: InStream into MemoryStream copies all bytes (Length 11) and leaves the position at the end;
//    MemoryStream into an OutStream copies the WHOLE stream whatever its Position (6 or 0) and leaves the position at 0; with a
//    count of 5 it copies the first 5 bytes and leaves Position 5; an InStream already read by 1 byte copies the remaining 10.
//  - DateTimeOffset: LocalDateTime is a DotNet DateTime that converts to an AL DateTime; Offset converts to a Duration (blank when zero).
// BC versions: 27.5

dotnet
{
    assembly("mscorlib")
    {
        type("System.Convert"; DnConvert) { }
        type("System.String"; DnString) { }
        type("System.Guid"; DnGuid) { }
        type("System.DateTime"; DnDateTime) { }
        type("System.TimeSpan"; DnTimeSpan) { }
        type("System.Globalization.NumberStyles"; DnNumberStyles) { }
        type("System.Text.StringBuilder"; DnStringBuilder) { }
        type("System.DayOfWeek"; DnDayOfWeek) { }
        type("System.Object"; DnObject) { }
        type("System.Environment"; DnEnvironment) { }
        type("System.Type"; DnType) { }
        type("System.DateTimeOffset"; DnDateTimeOffset) { }
        type("System.IO.MemoryStream"; DnMemoryStream) { }
        type("System.String[]"; DnStringArray) { }
        type("System.Collections.ArrayList"; DnArrayList) { }
        type("System.Collections.Queue"; DnQueue) { }
        type("System.Text.Encoding"; QaDnEncoding) { }
        type("System.Byte[]"; QaDnByteArray) { }
    }
    assembly("System")
    {
        type("System.Uri"; DnUri) { }
    }
}

codeunit 61400 "Test DotNet Value Kinds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Kind(Value: Variant): Text
    begin
        if Value.IsInteger() then
            exit('Integer');
        if Value.IsBigInteger() then
            exit('BigInteger');
        if Value.IsDecimal() then
            exit('Decimal');
        if Value.IsText() then
            exit('Text');
        if Value.IsBoolean() then
            exit('Boolean');
        if Value.IsDateTime() then
            exit('DateTime');
        if Value.IsDuration() then
            exit('Duration');
        if Value.IsGuid() then
            exit('Guid');
        if Value.IsChar() then
            exit('Char');
        if Value.IsByte() then
            exit('Byte');
        if Value.IsDotNet() then
            exit('DotNet');
        exit('none');
    end;

    [Test]
    procedure ClrResults_ReadAsTheirAlKind()
    var
        Conv: DotNet DnConvert;
        Env: DotNet DnEnvironment;
        When: DotNet DnDateTime;
        Span: DotNet DnTimeSpan;
        Ident: DotNet DnGuid;
        Styles: DotNet DnNumberStyles;
        Value: Variant;
    begin
        Value := Conv.ToInt32('5');
        Assert.AreEqual('Integer', Kind(Value), 'int');
        Value := Conv.ToInt16('5');
        Assert.AreEqual('Integer', Kind(Value), 'short');
        Value := Conv.ToInt64('5');
        Assert.AreEqual('BigInteger', Kind(Value), 'long');
        Value := Conv.ToByte('5');
        Assert.AreEqual('Byte', Kind(Value), 'byte');
        Value := Conv.ToChar(65);
        Assert.AreEqual('Char', Kind(Value), 'char');
        Assert.AreEqual('A', Format(Value), 'char text');
        Value := Conv.ToSingle('1.5');
        Assert.AreEqual('Decimal', Kind(Value), 'float');
        Value := Conv.ToDouble('1.5');
        Assert.AreEqual('Decimal', Kind(Value), 'double');
        Value := Conv.ToDecimal('1.5');
        Assert.AreEqual('Decimal', Kind(Value), 'decimal');
        Value := Conv.ToBoolean('true');
        Assert.AreEqual('Boolean', Kind(Value), 'bool');
        Value := Conv.ToString(5);
        Assert.AreEqual('Text', Kind(Value), 'string');
        Value := Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400');
        Assert.AreEqual('none', Kind(Value), 'null string');

        When := When.Now;
        Value := When;
        Assert.AreEqual('DateTime', Kind(Value), 'DateTime');
        Value := When.Year;
        Assert.AreEqual('Integer', Kind(Value), 'int property');
        Value := When.DayOfWeek;
        Assert.AreEqual('DotNet', Kind(Value), 'enum property');
        Span := Span.Parse('00:01:30');
        Value := Span;
        Assert.AreEqual('Duration', Kind(Value), 'TimeSpan');
        Assert.AreEqual('1 minute 30 seconds', Format(Value), 'TimeSpan text');
        Ident := Ident.NewGuid();
        Value := Ident;
        Assert.AreEqual('Guid', Kind(Value), 'Guid');
        Styles := Styles.Number;
        Value := Styles;
        Assert.AreEqual('DotNet', Kind(Value), 'enum');
        Assert.AreEqual('Number', Format(Value), 'enum text');
    end;

    [Test]
    procedure IntegerProperties_TakePartInIntegerExpressions_AndStringCompareIsCaseSensitive()
    var
        Builder: DotNet DnStringBuilder;
        Address: DotNet DnUri;
        Total: Integer;
        Index: Integer;
    begin
        Builder := Builder.StringBuilder();
        Builder.Append('abcd');
        Assert.AreEqual(3, Builder.Length - 1, 'Length - 1');
        for Index := 1 to Builder.Length - 1 do
            Total += 1;
        Assert.AreEqual(3, Total, 'for bound');
        Assert.AreEqual(2, Builder.Length div 2, 'div');

        Address := Address.Uri('https://example.com/x');
        Assert.IsFalse(Address.Scheme = 'HTTPS', 'case sensitive');
        Assert.IsTrue(Address.Scheme = 'https', 'same case');
    end;

    [Test]
    procedure NullStringResult_IsEmptyInExpressions()
    var
        Env: DotNet DnEnvironment;
        Text: Text;
        Value: Variant;
    begin
        Assert.IsTrue(Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400') = '', '= empty');
        Text := Format(Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400'));
        Assert.AreEqual('', Text, 'Format');
        Text := Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400') + 'x';
        Assert.AreEqual('x', Text, '+ x');
        Text := Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400');
        Assert.AreEqual(0, StrLen(Text), 'assigned to Text');
        Value := Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400');
        Assert.IsFalse(Value.IsText(), 'Variant is not Text');
        Assert.IsFalse(Value.IsDotNet(), 'Variant is not DotNet');
    end;

    [Test]
    procedure FormatOfDotNetObjects_IsToString()
    var
        Builder: DotNet DnStringBuilder;
        Kind: DotNet DnType;
        Styles: DotNet DnNumberStyles;
        Day: DotNet DnDayOfWeek;
        Nothing: DotNet DnObject;
    begin
        Builder := Builder.StringBuilder();
        Builder.Append('hello');
        Kind := Builder.GetType();
        Assert.AreEqual('System.Text.StringBuilder', Format(Kind), 'Type');
        Assert.AreEqual('System.Text.StringBuilder', Format(Kind, 0, 2), 'Type, 0, 2');
        Styles := Styles.Number;
        Assert.AreEqual('Number', Format(Styles), 'enum');
        Assert.AreEqual('Number', Format(Styles, 0, 2), 'enum, 0, 2');
        Assert.AreEqual('Number', Format(Styles, 0, 0), 'enum, 0, 0');
        Assert.AreEqual('hello', Format(Builder), 'StringBuilder');
        Assert.AreEqual('hello', Format(Builder, 0, 2), 'StringBuilder, 0, 2');
        Day := Day.Monday;
        Assert.AreEqual('Monday', Format(Day), 'DayOfWeek');
        Assert.IsTrue(IsNull(Nothing), 'IsNull of an unassigned object');
        Assert.IsFalse(IsNull(Builder), 'IsNull of an object');
    end;

    [Test]
    procedure EnumOperators()
    var
        Number: DotNet DnNumberStyles;
        Also: DotNet DnNumberStyles;
        Other: DotNet DnNumberStyles;
    begin
        Number := Number.Number;
        Also := Also.Number;
        Other := Other.AllowCurrencySymbol;

        Assert.IsTrue(Number = Also, 'equal');
        Assert.IsFalse(Number = Other, 'other');
        Assert.IsTrue(Number <> Other, '<>');
        Assert.AreEqual('367', Format(Number + Other), 'sum');
        Assert.AreEqual('111', Format(Number + 0), 'plus 0');
    end;

    [Test]
    procedure Foreach_OverClrCollections()
    var
        Text: DotNet DnString;
        Parts: DotNet DnStringArray;
        Numbers: DotNet DnArrayList;
        Waiting: DotNet DnQueue;
        Piece: Text;
        Number: Integer;
        Anything: Variant;
        Total: Text;
    begin
        Text := 'a,b,c';
        Parts := Text.Split(',');
        foreach Piece in Parts do
            Total += Piece + '|';
        Assert.AreEqual('a|b|c|', Total, 'string[]');

        Numbers := Numbers.ArrayList();
        Numbers.Add(1);
        Numbers.Add(2);
        Numbers.Add(3);
        Total := '';
        foreach Number in Numbers do
            Total += Format(Number) + '|';
        Assert.AreEqual('1|2|3|', Total, 'ArrayList into Integer');
        Total := '';
        foreach Anything in Numbers do
            Total += Format(Anything) + '/' + Format(Anything.IsInteger()) + '|';
        Assert.AreEqual('1/Yes|2/Yes|3/Yes|', Total, 'ArrayList into Variant');

        Waiting := Waiting.Queue();
        Waiting.Enqueue('x');
        Waiting.Enqueue('y');
        Total := '';
        foreach Piece in Waiting do
            Total += Piece + '|';
        Assert.AreEqual('x|y|', Total, 'Queue');
        Assert.AreEqual(2, Waiting.Count, 'the Queue is not consumed');

        Text := 'hey';
        Total := '';
        foreach Piece in Text do
            Total += Piece + '|';
        Assert.AreEqual('h|e|y|', Total, 'string');
    end;

    [Test]
    procedure Foreach_Failures_HaveTheirTextsAndCodes()
    var
        Numbers: DotNet DnArrayList;
        Texts: DotNet DnArrayList;
        Missing: DotNet DnArrayList;
        Piece: Text;
        Number: Integer;
        Day: Date;
        Count: Integer;
    begin
        Numbers := Numbers.ArrayList();
        Numbers.Add(1);
        Numbers.Add(2);

        asserterror foreach Piece in Numbers do;
#if BC28PLUS
        Assert.AreEqual('The value "1" can''t be evaluated into type Text.', GetLastErrorText(), 'Text over int');
        Assert.AreEqual('Evaluate:Argument', GetLastErrorCode(), 'Text over int: code');
#else
        Assert.AreEqual('Invalid Conversion. Source: Int32, Destination: NavText.', GetLastErrorText(), 'Text over int');
        Assert.AreEqual('Argument', GetLastErrorCode(), 'Text over int: code');
#endif

        asserterror foreach Number in Numbers do begin
            Count += 1;
            if Count = 1 then
                Numbers.Add(3);
        end;
        Assert.AreEqual(1, Count, 'the loop stops after the first element');
        Assert.AreEqual('A call to System.Collections.ArrayList+ArrayListEnumeratorSimple.MoveNext failed with this message: Collection was modified; enumeration operation may not execute.', GetLastErrorText(), 'modified');
        Assert.AreEqual('DotNetInvoke:InvalidOperation', GetLastErrorCode(), 'modified: code');

        asserterror foreach Number in Missing do;
        Assert.AreEqual('A DotNet variable has not been instantiated. Attempting to call System.Collections.ArrayList.GetEnumerator in CodeUnit Test DotNet Value Kinds: Foreach_Failures_HaveTheirTextsAndCodes', GetLastErrorText(), 'null collection');
        Assert.AreEqual('DotNetVariableNotCreated', GetLastErrorCode(), 'null collection: code');

        Texts := Texts.ArrayList();
        Texts.Add('text');
        asserterror foreach Day in Texts do;
#if BC28PLUS
        Assert.IsTrue(GetLastErrorText().StartsWith('The format of the Date ''text'' does not match your device''s date settings.'), 'Date over text');
        Assert.AreEqual('Evaluate:Conversion', GetLastErrorCode(), 'Date over text: code');
#else
        Assert.AreEqual('Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavText to System.DateTime.', GetLastErrorText(), 'Date over text');
        Assert.AreEqual('Conversion', GetLastErrorCode(), 'Date over text: code');
#endif
    end;

    local procedure BlobText(var Blob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Result: Text;
    begin
        Blob.CreateInStream(InStr);
        InStr.ReadText(Result);
        exit(Result);
    end;

    [Test]
    procedure CopyStream_WithAMemoryStream()
    var
        Memory: DotNet DnMemoryStream;
        Second: DotNet DnMemoryStream;
        Source: Codeunit "Temp Blob";
        Whole: Codeunit "Temp Blob";
        FromSix: Codeunit "Temp Blob";
        Counted: Codeunit "Temp Blob";
        SourceOut: OutStream;
        SourceIn: InStream;
        WholeOut: OutStream;
        SixOut: OutStream;
        CountedOut: OutStream;
        FirstByte: Byte;
    begin
        Source.CreateOutStream(SourceOut);
        SourceOut.WriteText('hello world');
        Source.CreateInStream(SourceIn);
        Memory := Memory.MemoryStream();

        CopyStream(Memory, SourceIn);
        Assert.AreEqual(11L, Memory.Length, 'Length');
        Assert.AreEqual(11L, Memory.Position, 'Position after the copy');
        Assert.IsTrue(SourceIn.EOS(), 'source read to the end');

        Memory.Position := 0;
        Whole.CreateOutStream(WholeOut);
        CopyStream(WholeOut, Memory);
        Assert.AreEqual('hello world', BlobText(Whole), 'from position 0');
        Assert.AreEqual(0L, Memory.Position, 'position after');

        Memory.Position := 6;
        FromSix.CreateOutStream(SixOut);
        CopyStream(SixOut, Memory);
        Assert.AreEqual('hello world', BlobText(FromSix), 'the whole stream whatever the position');
        Assert.AreEqual(0L, Memory.Position, 'position after');

        Memory.Position := 0;
        Counted.CreateOutStream(CountedOut);
        CopyStream(CountedOut, Memory, 5);
        Assert.AreEqual('hello', BlobText(Counted), 'with a count');
        Assert.AreEqual(5L, Memory.Position, 'position after a count');

        Source.CreateInStream(SourceIn);
        SourceIn.Read(FirstByte);
        Second := Second.MemoryStream();
        CopyStream(Second, SourceIn);
        Assert.AreEqual(10L, Second.Length, 'an InStream read by one byte copies the rest');
    end;

    [Test]
    procedure DateTimeOffset_LocalDateTimeAndOffset()
    var
        Stamp: DotNet DnDateTimeOffset;
        LocalTime: DotNet DnDateTime;
        Shifted: DateTime;
        Zone: Duration;
    begin
        Stamp := Stamp.Now;
        LocalTime := Stamp.LocalDateTime;
        Assert.IsTrue(LocalTime.Year > 2000, 'LocalDateTime is a DotNet DateTime');
        Shifted := LocalTime;
        Assert.AreNotEqual(0DT, Shifted, 'converts to a DateTime');
        Zone := Stamp.Offset;
        Assert.AreEqual('', Format(Zone), 'Offset converts to a Duration; zero reads blank on this host');
        Shifted := LocalTime - Stamp.Offset;
        Assert.AreNotEqual(0DT, Shifted, 'DateTime minus Duration');
    end;

    // al-runtime-rs backlog (partner gap, owner 2026-10-20, writer QA): a .NET method or property that returns System.String, assigned straight to a
    // SecretText variable, then IsEmpty, Unwrap, passed on as a SecretText parameter and through SecretStrSubstNo. Each case: ok|IsEmpty|Unwrap or the error.
    [TryFunction]
    local procedure QaTrySecret(CaseNo: Integer; var Secret: SecretText)
    var
        Conv: DotNet DnConvert;
        Str: DotNet DnString;
        Enc: DotNet QaDnEncoding;
        Bytes: DotNet QaDnByteArray;
        Env: DotNet DnEnvironment;
        Uri: DotNet DnUri;
    begin
        case CaseNo of
            1:
                begin
                    Bytes := Enc.UTF8.GetBytes('Hello');
                    Secret := Conv.ToBase64String(Bytes);
                end;
            2:
                Secret := Str.Concat('ab', 'cd');
            3:
                Secret := Str.Empty;
            4:
                Secret := Env.GetEnvironmentVariable('ARRS_NO_SUCH_VARIABLE_61400');
            5:
                begin
                    Uri := Uri.Uri('https://example.com/path?q=1');
                    Secret := Uri.Host;
                end;
            6:
                begin
                    Bytes := Conv.FromBase64String('SGVsbG8=');
                    Secret := Enc.UTF8.GetString(Bytes);
                end;
        end;
    end;

    local procedure QaShowSecret(Secret: SecretText): Text
    begin
        exit(Format(Secret.IsEmpty()) + '|' + Secret.Unwrap());
    end;

    local procedure QaPassOn(Secret: SecretText): SecretText
    begin
        exit(Secret);
    end;

    [Test]
    procedure QA_StringResult_IntoSecretText()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Conv: DotNet DnConvert;
        Enc: DotNet QaDnEncoding;
        CaseNo: Integer;
    begin
        for CaseNo := 1 to 6 do begin
            Clear(Secret);
            ClearLastError();
            if QaTrySecret(CaseNo, Secret) then
                Observer.Observe('case ' + Format(CaseNo), 'ok|' + QaShowSecret(Secret))
            else
                Observer.ObserveError('case ' + Format(CaseNo));
        end;
        Secret := QaPassOn(Conv.ToBase64String(Enc.UTF8.GetBytes('Hello')));
        Observer.Observe('passed as argument', QaShowSecret(Secret));
        Secret := SecretStrSubstNo('Basic %1', Conv.ToBase64String(Enc.UTF8.GetBytes('u:p')));
        Observer.Observe('SecretStrSubstNo', QaShowSecret(Secret));
        Observer.Finish();
    end;
}
