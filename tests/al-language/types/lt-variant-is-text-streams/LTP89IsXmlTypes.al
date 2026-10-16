// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/variant/variant-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 74634 "LT P89 Is Xml Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Flags(V: Variant): Text
    var
        R: Text;
    begin
        if V.IsXmlAttribute() then
            R += 'XmlAttribute,';
        if V.IsXmlAttributeCollection() then
            R += 'XmlAttributeCollection,';
        if V.IsXmlCData() then
            R += 'XmlCData,';
        if V.IsXmlComment() then
            R += 'XmlComment,';
        if V.IsXmlDeclaration() then
            R += 'XmlDeclaration,';
        if V.IsXmlDocument() then
            R += 'XmlDocument,';
        if V.IsXmlDocumentType() then
            R += 'XmlDocumentType,';
        if V.IsXmlElement() then
            R += 'XmlElement,';
        if V.IsXmlNameTable() then
            R += 'XmlNameTable,';
        if V.IsXmlNamespaceManager() then
            R += 'XmlNamespaceManager,';
        if V.IsXmlNode() then
            R += 'XmlNode,';
        if V.IsXmlNodeList() then
            R += 'XmlNodeList,';
        if V.IsXmlProcessingInstruction() then
            R += 'XmlProcessingInstruction,';
        if V.IsXmlText() then
            R += 'XmlText,';
        if V.IsXmlWriteOptions() then
            R += 'XmlWriteOptions,';
        if V.IsXmlReadOptions() then
            R += 'XmlReadOptions,';
        exit(R);
    end;

    [Test]
    procedure Document_Element_Attribute()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XDoc: XmlDocument;
        XEl: XmlElement;
        XAttr: XmlAttribute;
    begin
        XDoc := XmlDocument.Create();
        V := XDoc; Observer.Observe('document', Flags(V));
        XEl := XmlElement.Create('root');
        V := XEl; Observer.Observe('element', Flags(V));
        XAttr := XmlAttribute.Create('n', 'v');
        V := XAttr; Observer.Observe('attribute', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Comment_CData_Text()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XCom: XmlComment;
        XCd: XmlCData;
        XTx: XmlText;
    begin
        XCom := XmlComment.Create('c');
        V := XCom; Observer.Observe('comment', Flags(V));
        XCd := XmlCData.Create('data');
        V := XCd; Observer.Observe('cdata', Flags(V));
        XTx := XmlText.Create('txt');
        V := XTx; Observer.Observe('text', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Declaration_DocType_PI()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XDecl: XmlDeclaration;
        XDt: XmlDocumentType;
        XPi: XmlProcessingInstruction;
    begin
        XDecl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        V := XDecl; Observer.Observe('declaration', Flags(V));
        XDt := XmlDocumentType.Create('root', '', '', '');
        V := XDt; Observer.Observe('doctype', Flags(V));
        XPi := XmlProcessingInstruction.Create('target', 'data');
        V := XPi; Observer.Observe('pi', Flags(V));
        Observer.Finish();
    end;

    [Test]
    procedure Options_Defaults()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        XW: XmlWriteOptions;
        XR: XmlReadOptions;
    begin
        V := XW; Observer.Observe('write_options', Flags(V));
        XW.PreserveWhitespace(true);
        V := XW; Observer.Observe('write_options_set', Flags(V));
        V := XR; Observer.Observe('read_options', Flags(V));
        XR.PreserveWhitespace(true);
        V := XR; Observer.Observe('read_options_set', Flags(V));
        Observer.Finish();
    end;

}
