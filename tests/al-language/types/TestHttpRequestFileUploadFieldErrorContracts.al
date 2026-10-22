// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httprequestmessage/httprequestmessage-data-type
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 69124, codeunit 69125
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins:
//  - a new HttpRequestMessage has the method GET and an empty request uri; SetRequestUri of a text that is no uri answers false and keeps the
//    uri empty, of 'https://example.com/a?b=1' answers true and GetRequestUri gives it back; Method('post') is kept as written (post);
//  - a FileUpload variable no client filled: FileName() is a null string (passed straight to a Variant parameter it raises the uncatchable
//    ArgumentNullException of the DotNet tests), assigned to a Text it is ''; CreateInStream does not raise and opens an empty stream;
//  - FieldError(Field, ErrorInfo) and FieldError(Field, Text) raise "<field> <message> in <table> <key>='<value>'." with the code
//    NCLCSRTS:TableErrorStr, the message being the ErrorInfo's Message or the text.
// BC versions: 27.5

table 69124 "Probe FE Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 69125 "Probe Http FileUpload FE"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure HttpRequestMessage_Defaults_AndSetRequestUri()
    var
        Message: HttpRequestMessage;
    begin
        Assert.AreEqual('GET', Message.Method(), 'Method');
        Assert.AreEqual('', Message.GetRequestUri(), 'uri');
        Assert.IsFalse(Message.SetRequestUri('not a uri'), 'bad uri');
        Assert.AreEqual('', Message.GetRequestUri(), 'uri after a bad one');
        Assert.IsTrue(Message.SetRequestUri('https://example.com/a?b=1'), 'good uri');
        Assert.AreEqual('https://example.com/a?b=1', Message.GetRequestUri(), 'uri after a good one');
        Message.Method('post');
        Assert.AreEqual('post', Message.Method(), 'Method as written');
    end;

    [Test]
    procedure FileUpload_NoClientFilled_OpensAnEmptyStream()
    var
        Upload: FileUpload;
        InStr: InStream;
        Content: Text;
        Name: Text;
    begin
        Name := Upload.FileName();
        Assert.AreEqual('', Name, 'FileName assigned to a Text');

        Upload.CreateInStream(InStr);

        Assert.IsTrue(InStr.EOS(), 'empty stream');
        InStr.ReadText(Content);
        Assert.AreEqual('', Content, 'content');
    end;

    [Test]
    procedure FieldError_WithErrorInfoAndWithText()
    var
        FeRec: Record "Probe FE Table";
        Info: ErrorInfo;
    begin
        FeRec.Id := 5;
        Info.Message := 'custom message';

        asserterror FeRec.FieldError(Txt, Info);
        Assert.AreEqual('Txt custom message in Probe FE Table Id=''5''.', GetLastErrorText(), 'ErrorInfo text');
        Assert.AreEqual('NCLCSRTS:TableErrorStr', GetLastErrorCode(), 'ErrorInfo code');

        asserterror FeRec.FieldError(Txt, 'plain text');
        Assert.AreEqual('Txt plain text in Probe FE Table Id=''5''.', GetLastErrorText(), 'text');
        Assert.AreEqual('NCLCSRTS:TableErrorStr', GetLastErrorCode(), 'text code');
    end;
}
