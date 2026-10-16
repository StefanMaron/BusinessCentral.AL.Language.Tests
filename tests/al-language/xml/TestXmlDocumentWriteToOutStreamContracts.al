// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-writeto-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained codeunit 68990
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins XmlDocument.WriteTo(OutStream), WriteTo(XmlWriteOptions, OutStream) and XmlElement.WriteTo(OutStream) for
// <?xml version="1.0" encoding="utf-8"?><Root><A>1</A> <B>x</B></Root>:
//  - the bytes are UTF-8 with a byte order mark (239 187 191), whatever the encoding of the OutStream (UTF-8 and UTF-16
//    OutStreams give the same 75 bytes), and the declaration says encoding="utf-8";
//  - the text is the one WriteTo(Text) gives: declaration, a line feed, <Root>, a line feed, then the content indented two spaces
//    ("  <A>1</A> <B>x</B></Root>": an element with mixed content is not indented inside);
//  - XmlWriteOptions with PreserveWhitespace(true) writes the document as it came, on one line with no added line feeds and no indentation;
//    PreserveWhitespace(false) is the indented form;
//  - XmlElement.WriteTo(OutStream) writes the element alone (<Root>, a line feed, the indented content).
// BC versions: 27.5

codeunit 68990 "Probe XmlDoc WriteTo OutStream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Load(var Doc: XmlDocument)
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><Root><A>1</A> <B>x</B></Root>', Doc);
    end;

    local procedure Lines(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Result += Line + '|';
        end;
        exit(Result);
    end;

    local procedure LeadingBytes(var TempBlob: Codeunit "Temp Blob"): Text
    var
        InStr: InStream;
        Leading: Text[3];
        Bom: Text[3];
    begin
        Bom[1] := 239;
        Bom[2] := 187;
        Bom[3] := 191;
        TempBlob.CreateInStream(InStr);
        InStr.Read(Leading, 3);
        if Leading = Bom then
            exit('BOM size=' + Format(TempBlob.Length()));
        exit('no BOM size=' + Format(TempBlob.Length()));
    end;

    [Test]
    procedure WriteToOutStream_IsUtf8WithAByteOrderMark_WhateverTheStreamEncoding()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        Utf16Blob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Utf16Out: OutStream;
    begin
        Load(Doc);
        TempBlob.CreateOutStream(OutStr);
        Doc.WriteTo(OutStr);
        Utf16Blob.CreateOutStream(Utf16Out, TextEncoding::UTF16);
        Doc.WriteTo(Utf16Out);

        Assert.AreEqual('no BOM size=77', LeadingBytes(TempBlob), 'bytes');
        Assert.AreEqual(LeadingBytes(TempBlob), LeadingBytes(Utf16Blob), 'UTF-16 stream gives the same bytes');
        Assert.AreEqual('<?xml version="1.0" encoding="utf-8"?>|<Root>|  <A>1</A> <B>x</B></Root>|', Lines(TempBlob), 'text');
    end;

    [Test]
    procedure WriteToWithOptions_PreserveWhitespace()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Options: XmlWriteOptions;
    begin
        Load(Doc);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Options.PreserveWhitespace(true);
        Doc.WriteTo(Options, OutStr);
        Assert.AreEqual('<?xml version="1.0" encoding="utf-8"?><Root><A>1</A> <B>x</B></Root>|', Lines(TempBlob), 'true');

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Options.PreserveWhitespace(false);
        Doc.WriteTo(Options, OutStr);
        Assert.AreEqual('<?xml version="1.0" encoding="utf-8"?>|<Root>|  <A>1</A> <B>x</B></Root>|', Lines(TempBlob), 'false');
    end;

    [Test]
    procedure ElementWriteToOutStream_WritesTheElementAlone()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Load(Doc);
        Doc.GetRoot(Root);

        TempBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        Root.WriteTo(OutStr);

        Assert.AreEqual('<Root>|  <A>1</A> <B>x</B></Root>|', Lines(TempBlob), 'text');
    end;
}
