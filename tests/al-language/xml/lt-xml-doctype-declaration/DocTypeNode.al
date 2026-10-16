// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType as a node: IsXmlDocumentType, AsXmlDocumentType, Remove, ReplaceWith, AddBefore/AfterSelf, parent and document
// BC versions: 29 (27 and 28 by CI)

codeunit 72084 "LT P83 DocType Node"
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
    local procedure TryAsDocType(N: XmlNode)
    begin
        Dt := N.AsXmlDocumentType();
    end;

    [TryFunction]
    local procedure TryRemove()
    begin
        Dt.Remove();
    end;

    [TryFunction]
    local procedure TryReplaceWithElement(E: XmlElement)
    begin
        Dt.ReplaceWith(E);
    end;

    [TryFunction]
    local procedure TryReplaceWithDocType(D: XmlDocumentType)
    begin
        Dt.ReplaceWith(D);
    end;

    [TryFunction]
    local procedure TryGetParent(var P: XmlElement)
    begin
        Dt.GetParent(P);
    end;

    local procedure Written(): Text
    var
        T: Text;
    begin
        Doc.WriteTo(T);
        exit(T);
    end;

    local procedure NewDoc()
    begin
        Dt := XmlDocumentType.Create('a', '', 'a.dtd', '');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('a'));
    end;

    [Test]
    procedure TypeTests_OnDocType()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        N := Dt.AsXmlNode();
        Observer.Observe('is-doctype', Format(N.IsXmlDocumentType()));
        Observer.Observe('is-declaration', Format(N.IsXmlDeclaration()));
        Observer.Observe('is-element', Format(N.IsXmlElement()));
        Observer.Observe('is-document', Format(N.IsXmlDocument()));
        Observer.Observe('is-attribute', Format(N.IsXmlAttribute()));
        Observer.Observe('is-text', Format(N.IsXmlText()));
        Observer.Observe('is-comment', Format(N.IsXmlComment()));
        Observer.Observe('is-cdata', Format(N.IsXmlCData()));
        Observer.Observe('is-pi', Format(N.IsXmlProcessingInstruction()));
        Observer.Finish();
    end;

    [Test]
    procedure TypeTests_OnOtherNodes()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        N := XmlElement.Create('a').AsXmlNode();
        Observer.Observe('element', Format(N.IsXmlDocumentType()));
        N := XmlText.Create('t').AsXmlNode();
        Observer.Observe('text', Format(N.IsXmlDocumentType()));
        N := XmlComment.Create('c').AsXmlNode();
        Observer.Observe('comment', Format(N.IsXmlDocumentType()));
        N := XmlDocument.Create().AsXmlNode();
        Observer.Observe('document', Format(N.IsXmlDocumentType()));
        N := XmlAttribute.Create('x', 'y').AsXmlNode();
        Observer.Observe('attribute', Format(N.IsXmlDocumentType()));
        N := XmlDeclaration.Create('1.0', '', '').AsXmlNode();
        Observer.Observe('declaration', Format(N.IsXmlDocumentType()));
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlDocumentType_Conversion()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
    begin
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        N := Dt.AsXmlNode();
        Clear(Dt);
        Observer.Observe('convert', Format(TryAsDocType(N)));
        Observer.ObserveError('convert');
        Observer.Observe('members', GName(Dt) + '|' + GPub(Dt) + '|' + GSys(Dt) + '|' + GSub(Dt));
        N := XmlElement.Create('a').AsXmlNode();
        Observer.Observe('from-element', Format(TryAsDocType(N)));
        Observer.ObserveError('from-element');
        N := XmlText.Create('t').AsXmlNode();
        Observer.Observe('from-text', Format(TryAsDocType(N)));
        Observer.ObserveError('from-text');
        N := XmlDeclaration.Create('1.0', '', '').AsXmlNode();
        Observer.Observe('from-declaration', Format(TryAsDocType(N)));
        Observer.ObserveError('from-declaration');
        Observer.Finish();
    end;

    [Test]
    procedure AsXmlDocumentType_FromDocumentChildren()
    var
        Observer: Codeunit "Probe Observer";
        Nodes: XmlNodeList;
        N: XmlNode;
        i: Integer;
    begin
        NewDoc();
        Nodes := Doc.GetChildNodes();
        i := 0;
        foreach N in Nodes do begin
            i += 1;
            Observer.Observe('child' + Format(i) + '-doctype', Format(N.IsXmlDocumentType()));
            Observer.Observe('child' + Format(i) + '-element', Format(N.IsXmlElement()));
        end;
        Observer.Observe('count', Format(i));
        Observer.Finish();
    end;

    [Test]
    procedure Remove_DocType()
    var
        Observer: Codeunit "Probe Observer";
        Got: XmlDocumentType;
    begin
        NewDoc();
        Observer.Observe('before', Written());
        Doc.GetDocumentType(Got);
        Got.Remove();
        Observer.Observe('after', Written());
        Observer.Observe('has-type', Format(Doc.GetDocumentType(Got)));
        Observer.Observe('children', Format(Doc.GetChildNodes().Count()));
        Observer.Observe('remove-twice', Format(TryRemoveGot(Got)));
        Observer.ObserveError('remove-twice');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryRemoveGot(Got: XmlDocumentType)
    begin
        Got.Remove();
    end;

    [Test]
    procedure Remove_DetachedDocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('remove', Format(TryRemove()));
        Observer.ObserveError('remove');
        Observer.Observe('name', GName(Dt));
        Observer.Finish();
    end;

    [Test]
    procedure Remove_ThenReAdd()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewDoc();
        Dt.Remove();
        Observer.Observe('removed', Written());
        Doc := XmlDocument.Create();
        Doc.Add(Dt);
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('re-added', Written());
        Observer.Observe('name', GName(Dt));
        Observer.Finish();
    end;

    [Test]
    procedure ReplaceWith_DocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewDoc();
        Observer.Observe('replace', Format(TryReplaceWithDocType(XmlDocumentType.Create('b', 'p', '', ''))));
        Observer.ObserveError('replace');
        Observer.Observe('after', Written());
        Observer.Observe('old-name', GName(Dt));
        Observer.Finish();
    end;

    [Test]
    procedure ReplaceWith_Element()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewDoc();
        Observer.Observe('replace', Format(TryReplaceWithElement(XmlElement.Create('x'))));
        Observer.ObserveError('replace');
        Observer.Observe('after', Written());
        Observer.Observe('children', Format(Doc.GetChildNodes().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure ReplaceWith_DetachedDocType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('replace', Format(TryReplaceWithDocType(XmlDocumentType.Create('b', '', '', ''))));
        Observer.ObserveError('replace');
        Observer.Finish();
    end;

    [Test]
    procedure AddAfterSelf_AddBeforeSelf()
    var
        Observer: Codeunit "Probe Observer";
    begin
        NewDoc();
        Observer.Observe('after-comment', Format(TryAddAfter(XmlComment.Create('c'))));
        Observer.ObserveError('after-comment');
        Observer.Observe('written', Written());
        Observer.Observe('before-comment', Format(TryAddBefore(XmlComment.Create('d'))));
        Observer.ObserveError('before-comment');
        Observer.Observe('written2', Written());
        Observer.Observe('before-doctype', Format(TryAddBeforeDt(XmlDocumentType.Create('b', '', '', ''))));
        Observer.ObserveError('before-doctype');
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAddAfter(C: XmlComment)
    begin
        Dt.AddAfterSelf(C);
    end;

    [TryFunction]
    local procedure TryAddBefore(C: XmlComment)
    begin
        Dt.AddBeforeSelf(C);
    end;

    [TryFunction]
    local procedure TryAddBeforeDt(D: XmlDocumentType)
    begin
        Dt.AddBeforeSelf(D);
    end;

    [Test]
    procedure ParentAndDocument()
    var
        Observer: Codeunit "Probe Observer";
        P: XmlElement;
        D2: XmlDocument;
    begin
        NewDoc();
        Observer.Observe('parent', Format(TryGetParent(P)));
        Observer.ObserveError('parent');
        Observer.Observe('get-document', Format(Dt.GetDocument(D2)));
        if Dt.GetDocument(D2) then
            Observer.Observe('document-children', Format(D2.GetChildNodes().Count()));
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('detached-parent', Format(TryGetParent(P)));
        Observer.ObserveError('detached-parent');
        Observer.Observe('detached-document', Format(Dt.GetDocument(D2)));
        Observer.Finish();
    end;

    [Test]
    procedure SelectNodes_OnDocType()
    var
        Observer: Codeunit "Probe Observer";
        Nodes: XmlNodeList;
        N: XmlNode;
    begin
        NewDoc();
        Observer.Observe('select', Format(Dt.SelectNodes('*', Nodes)));
        Observer.Observe('count', Format(Nodes.Count()));
        Observer.Observe('single', Format(Dt.SelectSingleNode('*', N)));
        Observer.Finish();
    end;
}
