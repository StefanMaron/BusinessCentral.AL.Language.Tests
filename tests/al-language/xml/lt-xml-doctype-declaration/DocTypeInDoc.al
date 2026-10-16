// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType added to a document, written with WriteTo, document type members
// BC versions: 29 (27 and 28 by CI)

codeunit 72081 "LT P83 DocType In Doc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Doc: XmlDocument;
        Dt: XmlDocumentType;

    local procedure GName(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetName(R);
        exit(R);
    end;

    local procedure GPub(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetPublicId(R);
        exit(R);
    end;

    local procedure GSys(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetSystemId(R);
        exit(R);
    end;

    local procedure GSub(D: XmlDocumentType): Text
    var
        R: Text;
    begin
        D.GetInternalSubset(R);
        exit(R);
    end;

    [TryFunction]
    local procedure TryAdd(Node: XmlDocumentType)
    begin
        Doc.Add(Node);
    end;

    [TryFunction]
    local procedure TryAddElement(E: XmlElement)
    begin
        Doc.Add(E);
    end;

    [TryFunction]
    local procedure TryGetType()
    begin
        Doc.GetDocumentType(Dt);
    end;

    local procedure Written(): Text
    var
        T: Text;
    begin
        Doc.WriteTo(T);
        exit(T);
    end;

    [Test]
    procedure DocumentCreate_WithDocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        asserterror Observer.Observe('only-doctype', Written());
        Observer.ObserveError('af82');
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('with-root', Written());
        Observer.Observe('get-bool', Format(Doc.GetDocumentType(Dt)));
        Observer.Observe('get-name', GName(Dt));
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure DocumentCreate_WithDeclarationAndDocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', 'pub', 'sys.dtd', '<!ELEMENT a EMPTY>');
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', 'utf-8', 'yes'), Dt);
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('written', Written());
        Observer.Observe('get-bool', Format(Doc.GetDocumentType(Dt)));
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', '', ''));
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('only-declaration', Written());
        Observer.Finish();
    end;

    [Test]
    procedure DocumentAdd_DocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc := XmlDocument.Create();
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('add-first', Format(TryAdd(Dt)));
        Observer.ObserveError('add-first');
        Observer.Observe('add-root', Format(TryAddElement(XmlElement.Create('a'))));
        Observer.ObserveError('add-root');
        Observer.Observe('written', Written());
        Observer.Observe('add-second', Format(TryAdd(XmlDocumentType.Create('b', '', '', ''))));
        Observer.ObserveError('add-second');
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure DocumentAdd_DocTypeAfterRoot()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Doc := XmlDocument.Create();
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('add-after-root', Format(TryAdd(XmlDocumentType.Create('a', '', '', ''))));
        Observer.ObserveError('add-after-root');
        Observer.Observe('written', Written());
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure DocumentAdd_DocTypeToElement()
    var
        Observer: Codeunit "Probe Observer";
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        Dt := XmlDocumentType.Create('a', '', '', '');
        asserterror E.Add(Dt);
        Observer.ObserveError('add-to-element');
        Observer.Observe('element-text', Format(E.HasElements()) + '|' + E.InnerXml());
        Observer.Finish();
    end;

    [Test]
    procedure DocumentAdd_SameDocTypeTwice()
    var
        Observer: Codeunit "Probe Observer";
        Doc2: XmlDocument;
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('a'));
        Doc2 := XmlDocument.Create();
        Observer.Observe('add-to-second', Format(TryAdd2(Doc2, Dt)));
        Observer.ObserveError('add-to-second');
        Observer.Observe('second-children', Format(Doc2.GetChildNodes().Count()));
        Observer.Observe('first-children', Format(Doc.GetChildNodes().Count()));
        Observer.Observe('first-written', Written());
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAdd2(D: XmlDocument; Node: XmlDocumentType)
    begin
        D.Add(Node);
    end;

    [Test]
    procedure GetDocumentType_Members()
    var
        Observer: Codeunit "Probe Observer";
        Got: XmlDocumentType;
    begin
        Dt := XmlDocumentType.Create('root', '-//P//EN', 'p.dtd', '<!ENTITY e "v">');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('root'));
        Observer.Observe('bool', Format(Doc.GetDocumentType(Got)));
        Observer.Observe('name', GName(Got));
        Observer.Observe('public', GPub(Got));
        Observer.Observe('system', GSys(Got));
        Observer.Observe('subset', GSub(Got));
        Observer.Finish();
    end;

    [Test]
    procedure GetDocumentType_Statement()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Observer.Observe('with', Format(TryGetType()));
        Observer.ObserveError('with');
        Doc := XmlDocument.Create();
        Observer.Observe('without', Format(TryGetType()));
        Observer.ObserveError('without');
        Clear(Doc);
        Observer.Observe('default-doc', Format(TryGetType()));
        Observer.ObserveError('default-doc');
        Observer.Finish();
    end;

    [Test]
    procedure DocumentWriteTo_ToOutStream_AndSelect()
    var
        Observer: Codeunit "Probe Observer";
        Nodes: XmlNodeList;
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('select-all', Format(Doc.SelectNodes('/*', Nodes)));
        Observer.Observe('select-count', Format(Nodes.Count()));
        Observer.Observe('child-type-1', ChildKind(1));
        Observer.Observe('child-type-2', ChildKind(2));
        Observer.Observe('child-type-3', ChildKind(3));
        Observer.Finish();
    end;

    local procedure ChildKind(Index: Integer): Text
    var
        Nodes: XmlNodeList;
        N: XmlNode;
    begin
        Nodes := Doc.GetChildNodes();
        if not Nodes.Get(Index, N) then
            exit('none');
        if N.IsXmlDocumentType() then
            exit('doctype');
        if N.IsXmlElement() then
            exit('element');
        if N.IsXmlDeclaration() then
            exit('declaration');
        exit('other');
    end;
}
