// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-writeto-method
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer", codeunit 85909 "LT DE Helper", System Application codeunit "Temp Blob"; self-contained codeunits 85906, 85907, 85908
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Leads (corpus issue 671):
//  - "XmlDocument.ReadFrom(InStream) fails with '0x00 is an invalid character'" (microsoft/AL#5235): XML text written with Write(Text)
//    (which adds a zero byte) or WriteText, then read back with XmlDocument.ReadFrom(InStream).
//  - "XML declaration encoding name casing" (microsoft/AL#2759) and "XmlDocument with ISO-8859-1 declaration written to an OutStream"
//    (microsoft/AL#660): what WriteTo(Text) and WriteTo(OutStream) write for a declaration created with ISO-8859-1, iso-8859-1, UTF-8 and
//    Windows-1252, and the bytes of an a-umlaut on OutStreams created with TextEncoding::Windows and MSDos.
//  - "XmlAttribute.Create('xmlns', uri) namespace declaration" (microsoft/AL#1900): adding such an attribute to an element and writing it.

codeunit 85906 "LT DE Xml ReadFrom ZeroByte"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Xml(): Text
    begin
        exit('<?xml version="1.0" encoding="UTF-8"?><Envelope><Header><Id>12345</Id></Header><Body><Item No="1">First</Item><Item No="2">Second</Item></Body></Envelope>');
    end;

    [TryFunction]
    local procedure TryRead(var TempBlob: Codeunit "Temp Blob"; var RootName: Text)
    var
        InS: InStream;
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        TempBlob.CreateInStream(InS);
        XmlDocument.ReadFrom(InS, Doc);
        Doc.GetRoot(Root);
        RootName := Root.Name();
    end;

    local procedure ObserveRead(var Observer: Codeunit "Probe Observer"; Name: Text; var TempBlob: Codeunit "Temp Blob")
    var
        RootName: Text;
    begin
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        ClearLastError();
        if TryRead(TempBlob, RootName) then
            Observer.Observe(Name + ' readfrom', 'ok ' + RootName)
        else
            Observer.Observe(Name + ' readfrom', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure ReadFromInStream_AfterWriteAndWriteText()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Xml());
        ObserveRead(Observer, 'writetext', TempBlob);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.Write(Xml());
        ObserveRead(Observer, 'write', TempBlob);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        OutS.Write(Xml());
        ObserveRead(Observer, 'write utf8', TempBlob);

        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.Write('<Envelope><Id>1</Id></Envelope>');
        ObserveRead(Observer, 'write no declaration', TempBlob);
        Observer.Finish();
    end;
}

codeunit 85907 "LT DE Xml Declaration Encoding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Build(Encoding: Text; Standalone: Text; var Doc: XmlDocument)
    var
        Helper: Codeunit "LT DE Helper";
        Root: XmlElement;
    begin
        Doc := XmlDocument.Create();
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', Encoding, Standalone));
        Root := XmlElement.Create('a');
        Root.Add(XmlText.Create(Helper.Umlaut()));
        Doc.Add(Root);
    end;

    local procedure ObserveText(var Observer: Codeunit "Probe Observer"; Encoding: Text)
    var
        Doc: XmlDocument;
        T: Text;
    begin
        Build(Encoding, '', Doc);
        Doc.WriteTo(T);
        Observer.Observe(Encoding + ' text', T);
    end;

    local procedure ObserveStream(var Observer: Codeunit "Probe Observer"; Name: Text; Encoding: Text; Standalone: Text; StreamEncoding: TextEncoding)
    var
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        Doc: XmlDocument;
        OutS: OutStream;
    begin
        Build(Encoding, Standalone, Doc);
        TempBlob.CreateOutStream(OutS, StreamEncoding);
        Doc.WriteTo(OutS);
        Observer.Observe(Name + ' bytes', Helper.HexOf(TempBlob));
    end;

    [Test]
    procedure WriteToText_EncodingNameCasing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveText(Observer, 'ISO-8859-1');
        ObserveText(Observer, 'iso-8859-1');
        ObserveText(Observer, 'UTF-8');
        ObserveText(Observer, 'Windows-1252');
        Observer.Finish();
    end;

    [Test]
    procedure WriteToOutStream_EncodingNameCasing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStream(Observer, 'ISO-8859-1 utf8 stream', 'ISO-8859-1', '', TextEncoding::UTF8);
        ObserveStream(Observer, 'UTF-8 utf8 stream', 'UTF-8', '', TextEncoding::UTF8);
        ObserveStream(Observer, 'Windows-1252 utf8 stream', 'Windows-1252', '', TextEncoding::UTF8);
        Observer.Finish();
    end;

    [Test]
    procedure WriteToOutStream_Iso88591_WindowsAndMSDosStreams()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStream(Observer, 'ISO-8859-1 yes windows stream', 'ISO-8859-1', 'yes', TextEncoding::Windows);
        ObserveStream(Observer, 'ISO-8859-1 yes msdos stream', 'ISO-8859-1', 'yes', TextEncoding::MSDos);
        Observer.Finish();
    end;

    [Test]
    procedure WriteToOutStream_LoadedIso88591Document()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT DE Helper";
        TempBlob: Codeunit "Temp Blob";
        Doc: XmlDocument;
        OutS: OutStream;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="ISO-8859-1"?><a>' + Helper.Umlaut() + '</a>', Doc);
        TempBlob.CreateOutStream(OutS, TextEncoding::Windows);
        Doc.WriteTo(OutS);
        Observer.Observe('loaded windows stream bytes', Helper.HexOf(TempBlob));
        Observer.Finish();
    end;
}

codeunit 85908 "LT DE Xml xmlns Attribute"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAdd(var E: XmlElement; A: XmlAttribute)
    begin
        E.Add(A);
    end;

    [TryFunction]
    local procedure TrySet(var E: XmlElement; Value: Text)
    begin
        E.SetAttribute('xmlns', Value);
    end;

    [TryFunction]
    local procedure TryWriteElement(E: XmlElement; var T: Text)
    begin
        E.WriteTo(T);
    end;

    [TryFunction]
    local procedure TryWriteDocument(E: XmlElement; var T: Text)
    var
        Doc: XmlDocument;
    begin
        Doc := XmlDocument.Create();
        Doc.Add(E);
        Doc.WriteTo(T);
    end;

    local procedure ObserveWrite(var Observer: Codeunit "Probe Observer"; Name: Text; E: XmlElement)
    var
        T: Text;
    begin
        ClearLastError();
        if TryWriteElement(E, T) then
            Observer.Observe(Name + ' element writeto', 'ok ' + T)
        else
            Observer.Observe(Name + ' element writeto', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryWriteDocument(E, T) then
            Observer.Observe(Name + ' document writeto', 'ok ' + T)
        else
            Observer.Observe(Name + ' document writeto', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Observe(Name + ' namespaceuri', '[' + E.NamespaceUri() + ']');
    end;

    local procedure ObserveAdd(var Observer: Codeunit "Probe Observer"; Name: Text; var E: XmlElement; A: XmlAttribute)
    begin
        ClearLastError();
        if TryAdd(E, A) then
            Observer.Observe(Name + ' add', 'ok')
        else
            Observer.Observe(Name + ' add', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure XmlnsAttribute_OnElementWithoutNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root');
        ObserveAdd(Observer, 'no ns', E, XmlAttribute.Create('xmlns', 'urn:x-obml:1.0'));
        ObserveWrite(Observer, 'no ns', E);
        Observer.Finish();
    end;

    [Test]
    procedure XmlnsAttribute_OnElementWithSameNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root', 'urn:x-obml:1.0');
        ObserveAdd(Observer, 'same ns', E, XmlAttribute.Create('xmlns', 'urn:x-obml:1.0'));
        ObserveWrite(Observer, 'same ns', E);
        Observer.Finish();
    end;

    [Test]
    procedure XmlnsAttribute_OnElementWithOtherNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root', 'urn:other');
        ObserveAdd(Observer, 'other ns', E, XmlAttribute.Create('xmlns', 'urn:x-obml:1.0'));
        ObserveWrite(Observer, 'other ns', E);
        Observer.Finish();
    end;

    [Test]
    procedure XmlnsSetAttribute_OnElementWithoutNamespace()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('Root');
        ClearLastError();
        if TrySet(E, 'urn:x-obml:1.0') then
            Observer.Observe('setattribute', 'ok')
        else
            Observer.Observe('setattribute', 'error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        ObserveWrite(Observer, 'setattribute', E);
        Observer.Finish();
    end;
}
