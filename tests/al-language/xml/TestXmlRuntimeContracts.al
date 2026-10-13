// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins what WriteTo writes for XmlDocument and XmlElement (a declaration with UTF-16 for a
// document, two-space indentation of element children, ` />` for an empty element), how
// white space is read and kept, the sharing rules of Add, namespace lookups, XPath support and
// the text and code of the XML errors.
// BC versions: 27.5

codeunit 68128 "Probe Xml Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        LineFeed: Text[1];

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        LineFeed[1] := 10;
    end;

    [Test]
    procedure XmlDocument_WriteTo_HasDeclarationAndTwoSpaceIndentation()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Child: XmlElement;
        Result: Text;
    begin
        Initialize();
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('root');
        Root.SetAttribute('a', 'v"<&>');
        Child := XmlElement.Create('child');
        Child.Add(XmlText.Create('t<&>"'));
        Root.Add(Child);
        Root.Add(XmlElement.Create('empty'));
        Root.Add(XmlComment.Create('c'));
        Doc.Add(Root);

        Doc.WriteTo(Result);

        Assert.AreEqual('<?xml version="1.0" encoding="utf-16"?>' + LineFeed +
            '<root a="v&quot;&lt;&amp;&gt;">' + LineFeed +
            '  <child>t&lt;&amp;&gt;"</child>' + LineFeed +
            '  <empty />' + LineFeed +
            '  <!--c-->' + LineFeed +
            '</root>', Result, 'document text: attributes escape quote, <, & and >; text escapes <, & and >');
    end;

    [Test]
    procedure XmlDocument_WriteTo_DeclarationOnTheDocumentIsWrittenWithItsOwnValues()
    var
        Doc: XmlDocument;
        Result: Text;
    begin
        Initialize();
        Doc := XmlDocument.Create();
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        Doc.Add(XmlElement.Create('root'));

        Doc.WriteTo(Result);

        Assert.AreEqual('<?xml version="1.0" encoding="utf-8" standalone="yes"?>' + LineFeed + '<root />', Result, 'declaration');
    end;

    [Test]
    procedure XmlElement_WriteTo_MixedContentIsNotIndented()
    var
        Root: XmlElement;
        Result: Text;
    begin
        Initialize();
        Root := XmlElement.Create('root');
        Root.Add(XmlText.Create('  '));
        Root.Add(XmlElement.Create('x'));

        Root.WriteTo(Result);

        Assert.AreEqual('<root>  <x /></root>', Result, 'an element with a text child is written on one line');
    end;

    [Test]
    procedure XmlDocument_ReadFrom_KeepsWhiteSpaceInsideAndOutsideTheRoot()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Result: Text;
    begin
        Initialize();

        Assert.IsTrue(XmlDocument.ReadFrom('<root>  <a/>  </root>', Doc), 'read');
        Doc.WriteTo(Result);
        Assert.AreEqual('<?xml version="1.0" encoding="utf-16"?>' + LineFeed + '<root>  <a />  </root>', Result, 'white space inside the root is kept');
        Doc.GetRoot(Root);
        Root.WriteTo(Result);
        Assert.AreEqual('<root>  <a />  </root>', Result, 'the element alone');

        Assert.IsTrue(XmlDocument.ReadFrom('  <root><a/></root>  ', Doc), 'read with white space around the root');
        Doc.WriteTo(Result);
        Assert.AreEqual('<?xml version="1.0" encoding="utf-16"?>  <root>' + LineFeed + '  <a />' + LineFeed + '</root>  ', Result, 'white space outside the root is kept too');
    end;

    [Test]
    procedure XmlDocument_ReadFrom_Invalid_ReturnsFalse_AndStatementFormThrows()
    var
        Doc: XmlDocument;
    begin
        Initialize();

        Assert.IsFalse(XmlDocument.ReadFrom('<root><a></root>', Doc), 'invalid XML');

        asserterror XmlDocument.ReadFrom('<root><a></root>', Doc);

        Assert.AreEqual('The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 8 does not match the end tag of ''root''. Line 1, position 12.'' at line 1 and position 12.', GetLastErrorText(), 'text');
        Assert.AreEqual('Xml:Xml', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure XmlElement_Add_SameNodeTwice_AndNodeWithAParent_AreCopied_FreeNodeIsShared()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Child: XmlElement;
        Other: XmlElement;
        Result: Text;
    begin
        Initialize();
        XmlDocument.ReadFrom('<root><a/></root>', Doc);
        Doc.GetRoot(Root);
        Child := XmlElement.Create('b');

        Root.Add(Child);
        Child.SetAttribute('x', '1');
        Root.WriteTo(Result);
        Assert.AreEqual('<root>' + LineFeed + '  <a />' + LineFeed + '  <b x="1" />' + LineFeed + '</root>', Result, 'a free node is shared with its parent');

        Other := XmlElement.Create('other');
        Other.Add(Child);
        Child.SetAttribute('y', '2');
        Other.WriteTo(Result);
        Assert.AreEqual('<other>' + LineFeed + '  <b x="1" />' + LineFeed + '</other>', Result, 'a node that already has a parent is copied into the second parent');
        Root.WriteTo(Result);
        Assert.AreEqual('<root>' + LineFeed + '  <a />' + LineFeed + '  <b x="1" y="2" />' + LineFeed + '</root>', Result, 'the first parent holds the original');
    end;

    [Test]
    procedure XmlElement_Add_Text_IsAccepted_AndAdjacentTextsMerge()
    var
        Root: XmlElement;
        Result: Text;
    begin
        Initialize();
        Root := XmlElement.Create('r');

        Root.Add('plain text');
        Root.Add(XmlText.Create('a'));
        Root.Add(XmlText.Create('b'));

        Root.WriteTo(Result);
        Assert.AreEqual('<r>plain textab</r>', Result, 'text added as a string and as nodes');
    end;

    [Test]
    procedure XmlDocument_Add_SecondRoot_Throws()
    var
        Doc: XmlDocument;
    begin
        Initialize();
        Doc.Add(XmlElement.Create('r1'));

        asserterror Doc.Add(XmlElement.Create('r2'));

        Assert.AreEqual('The requested operation cannot be performed in this context.', GetLastErrorText(), 'text');
        Assert.AreEqual('InvalidOperation', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure XmlNode_CDataIsNotText()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Node: XmlNode;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r><![CDATA[x]]></r>', Doc);
        Doc.GetRoot(Root);

        Root.GetChildNodes().Get(1, Node);

        Assert.IsFalse(Node.IsXmlText(), 'IsXmlText');
        Assert.IsTrue(Node.IsXmlCData(), 'IsXmlCData');
    end;

    [Test]
    procedure XmlElement_NamespaceLookups()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Found: Text;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r xmlns="urn:d" xmlns:p="urn:p"><p:c/></r>', Doc);
        Doc.GetRoot(Root);

        Assert.IsTrue(Root.GetPrefixOfNamespace('urn:d', Found), 'default namespace has a prefix lookup');
        Assert.AreEqual('', Found, 'which is empty');
        Assert.IsTrue(Root.GetPrefixOfNamespace('urn:p', Found), 'prefixed namespace');
        Assert.AreEqual('p', Found, 'prefix p');
        Found := 'untouched';
        Assert.IsFalse(Root.GetNamespaceOfPrefix('', Found), 'the empty prefix has no namespace');
        Assert.AreEqual('untouched', Found, 'and leaves the variable alone');
        Assert.IsTrue(Root.GetNamespaceOfPrefix('p', Found), 'prefix p');
        Assert.AreEqual('urn:p', Found, 'namespace of p');
        Found := 'untouched';
        Assert.IsFalse(Root.GetNamespaceOfPrefix('zz', Found), 'unknown prefix');
        Assert.AreEqual('untouched', Found, 'and leaves the variable alone');
    end;

    [Test]
    procedure XmlNode_ParentAndDocument_OfRootAndOfAFreeElement()
    var
        Doc: XmlDocument;
        Doc2: XmlDocument;
        Root: XmlElement;
        Parent: XmlElement;
        Free: XmlElement;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r><a/></r>', Doc);
        Doc.GetRoot(Root);
        Free := XmlElement.Create('free');

        Assert.IsFalse(Root.GetParent(Parent), 'a root element has no parent element');
        Assert.IsTrue(Root.AsXmlNode().GetDocument(Doc2), 'but it has a document');
        Assert.IsFalse(Free.GetParent(Parent), 'a free element has no parent');
        Assert.IsFalse(Free.AsXmlNode().GetDocument(Doc2), 'and no document');
    end;

    [Test]
    procedure XmlDocument_GetDocumentType_WithoutDoctype()
    var
        Doc: XmlDocument;
        DocType: XmlDocumentType;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r/>', Doc);

        Assert.IsFalse(Doc.GetDocumentType(DocType), 'the Boolean form returns false');

        asserterror Doc.GetDocumentType(DocType);

        Assert.AreEqual('The XML node is not set.', GetLastErrorText(), 'text');
        Assert.AreEqual('XmlNodeNotFound', GetLastErrorCode(), 'code');
    end;

    [Test]
    procedure XmlDocument_SelectNodes_XPathSupport()
    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r><a x="1"><b>t</b></a><a x="2"/></r>', Doc);

        Doc.SelectNodes('/r/a[@x=''2'']', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'attribute predicate');
        Doc.SelectNodes('//a', Nodes);
        Assert.AreEqual(2, Nodes.Count(), 'descendant');
        Doc.SelectNodes('/r/a[2]', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'position');
        Doc.SelectNodes('/r/a/b/text()', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'text()');
        Doc.SelectNodes('/r/a[last()]', Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'last()');
        Doc.SelectNodes('/r/*[local-name()=''a'']', Nodes);
        Assert.AreEqual(2, Nodes.Count(), 'local-name()');
    end;

    [Test]
    procedure XmlDocument_SelectNodes_DefaultNamespace_NeedsAPrefixedName()
    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
        Namespaces: XmlNamespaceManager;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r xmlns="urn:d"><a/></r>', Doc);

        Doc.SelectNodes('/r/a', Nodes);
        Assert.AreEqual(0, Nodes.Count(), 'unprefixed names match no-namespace elements only');

        Namespaces.NameTable(Doc.NameTable());
        Namespaces.AddNamespace('d', 'urn:d');
        Doc.SelectNodes('/d:r/d:a', Namespaces, Nodes);
        Assert.AreEqual(1, Nodes.Count(), 'a prefix from the namespace manager');
    end;

    [Test]
    procedure XmlDocument_SelectNodes_NotANodeSet_Throws()
    var
        Doc: XmlDocument;
        Nodes: XmlNodeList;
    begin
        Initialize();
        XmlDocument.ReadFrom('<r><a/></r>', Doc);

        asserterror Doc.SelectNodes('/r/@@@', Nodes);

        Assert.AreEqual('Expression must evaluate to a node-set.', GetLastErrorText(), 'text');
        Assert.AreEqual('Xml:XPath', GetLastErrorCode(), 'code');
    end;
}
