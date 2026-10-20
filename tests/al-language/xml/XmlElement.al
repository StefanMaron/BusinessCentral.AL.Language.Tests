// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmlelement/xmlelement-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 73401
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73401 "LT XmT Element"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Load(Src: Text; var Root: XmlElement)
    var
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom(Src, Doc);
        Doc.GetRoot(Root);
    end;

    local procedure Str(E: XmlElement): Text
    var
        Txt: Text;
    begin
        E.WriteTo(Txt);
        exit(Txt);
    end;

    [Test]
    procedure Create_Name()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        Observer.Observe('name', E.Name());
        Observer.Observe('local', E.LocalName());
        Observer.Observe('ns', '[' + E.NamespaceUri() + ']');
        Observer.Observe('out', Str(E));
        Observer.Observe('empty', Format(E.IsEmpty()));
        Observer.Observe('haselements', Format(E.HasElements()));
        Observer.Observe('hasattrs', Format(E.HasAttributes()));
        Observer.Expect('name', 'a');
        Observer.Expect('local', 'a');
        Observer.Expect('ns', '[]');
        Observer.Expect('out', '<a />');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('haselements', 'No');
        Observer.Expect('hasattrs', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Create_Namespace()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a', 'urn:x');
        Observer.Observe('name', E.Name());
        Observer.Observe('local', E.LocalName());
        Observer.Observe('ns', E.NamespaceUri());
        Observer.Observe('out', Str(E));
        Observer.Expect('name', ':a');
        Observer.Expect('local', 'a');
        Observer.Expect('ns', 'urn:x');
        Observer.Expect('out', '<a xmlns="urn:x" />');
        Observer.Verify();
    end;

    [Test]
    procedure Create_Content()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a', '', 'text');
        Observer.Observe('text', Str(E));
        E := XmlElement.Create('a', 'urn:x', XmlElement.Create('b'));
        Observer.Observe('child', Str(E));
        E := XmlElement.Create('a', '', XmlAttribute.Create('k', 'v'));
        Observer.Observe('attr', Str(E));
        E := XmlElement.Create('a', '', XmlAttribute.Create('k', 'v'), XmlText.Create('t'), XmlComment.Create('c'));
        Observer.Observe('mixed', Str(E));
        E := XmlElement.Create('a', '', XmlCData.Create('<x>'));
        Observer.Observe('cdata', Str(E));
        E := XmlElement.Create('a', '', XmlProcessingInstruction.Create('pi', 'data'));
        Observer.Observe('pi', Str(E));
        Observer.Expect('text', '<a>text</a>');
        Observer.Expect('child', '<a xmlns="urn:x">\r\n  <b xmlns="" />\r\n</a>');
        Observer.Expect('attr', '<a k="v" />');
        Observer.Expect('mixed', '<a k="v">t<!--c--></a>');
        Observer.Expect('cdata', '<a><![CDATA[<x>]]></a>');
        Observer.Expect('pi', '<a>\r\n  <?pi data?>\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Create_InvalidNames()
    var
        E: XmlElement;
    begin
        asserterror E := XmlElement.Create('');
        Observer.ObserveError('empty');
        asserterror E := XmlElement.Create('1a');
        Observer.ObserveError('digit_first');
        asserterror E := XmlElement.Create('a b');
        Observer.ObserveError('space');
        asserterror E := XmlElement.Create('a<b');
        Observer.ObserveError('lt');
        asserterror E := XmlElement.Create('a:b');
        Observer.ObserveError('colon');
        asserterror E := XmlElement.Create('a/b');
        Observer.ObserveError('slash');
        asserterror E := XmlElement.Create('-a');
        Observer.ObserveError('dash_first');
        asserterror E := XmlElement.Create('a&b');
        Observer.ObserveError('amp');
        E := XmlElement.Create('_a-b.c1');
        Observer.Observe('valid_chars', E.Name());
        E := XmlElement.Create('ä');
        Observer.Observe('unicode_name', E.Name());
        Observer.Expect('empty|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('digit_first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''1'' character, hexadecimal value 0x31.'' at line 0 and position 1.');
        Observer.Expect('digit_first|code', 'Xml:Xml');
        Observer.Expect('space|text', 'The following exception was encountered when processing XML data: ''The '' '' character, hexadecimal value 0x20, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('space|code', 'Xml:Xml');
        Observer.Expect('lt|text', 'The following exception was encountered when processing XML data: ''The ''<'' character, hexadecimal value 0x3C, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('lt|code', 'Xml:Xml');
        Observer.Expect('colon|text', 'The following exception was encountered when processing XML data: ''The '':'' character, hexadecimal value 0x3A, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('colon|code', 'Xml:Xml');
        Observer.Expect('slash|text', 'The following exception was encountered when processing XML data: ''The ''/'' character, hexadecimal value 0x2F, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('slash|code', 'Xml:Xml');
        Observer.Expect('dash_first|text', 'The following exception was encountered when processing XML data: ''Name cannot begin with the ''-'' character, hexadecimal value 0x2D.'' at line 0 and position 1.');
        Observer.Expect('dash_first|code', 'Xml:Xml');
        Observer.Expect('amp|text', 'The following exception was encountered when processing XML data: ''The ''&'' character, hexadecimal value 0x26, cannot be included in a name.'' at line 0 and position 2.');
        Observer.Expect('amp|code', 'Xml:Xml');
        Observer.Expect('valid_chars', '_a-b.c1');
        Observer.Expect('unicode_name', 'ä');
        Observer.Verify();
    end;

    [Test]
    procedure Create_Escaping()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a', '', '<&>"''');
        Observer.Observe('out', Str(E));
        Observer.Observe('inner', E.InnerText());
        Observer.Observe('innerxml', E.InnerXml());
        Observer.Expect('out', '<a>&lt;&amp;&gt;"''</a>');
        Observer.Expect('inner', '<&>"''');
        Observer.Expect('innerxml', '&lt;&amp;&gt;"''');
        Observer.Verify();
    end;

    [Test]
    procedure InnerText_Set_Get()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlText.Create('x<y'));
        Observer.Observe('inner', E.InnerText());
        Observer.Observe('innerxml', E.InnerXml());
        Observer.Observe('out', Str(E));
        Observer.Expect('inner', 'x<y');
        Observer.Expect('innerxml', 'x&lt;y');
        Observer.Expect('out', '<a>x&lt;y</a>');
        Observer.Verify();
    end;

    [Test]
    procedure InnerText_Nested()
    var
        E: XmlElement;
    begin
        Load('<a>one<b>two<c>three</c></b>four</a>', E);
        Observer.Observe('inner', E.InnerText());
        Observer.Observe('innerxml', E.InnerXml());
        Load('<a>1<!--c-->2<?pi d?>3</a>', E);
        Observer.Observe('with_comment_pi', E.InnerText());
        Observer.Observe('with_comment_pi_xml', E.InnerXml());
        Load('<a><![CDATA[<x>]]></a>', E);
        Observer.Observe('cdata', E.InnerText());
        Observer.Observe('cdata_xml', E.InnerXml());
        Load('<a/>', E);
        Observer.Observe('empty_inner', '[' + E.InnerText() + ']');
        Observer.Observe('empty_xml', '[' + E.InnerXml() + ']');
        Observer.Expect('inner', 'onetwothreefour');
        Observer.Expect('innerxml', 'one<b>two<c>three</c></b>four');
        Observer.Expect('with_comment_pi', '123');
        Observer.Expect('with_comment_pi_xml', '1<!--c-->2<?pi d?>3');
        Observer.Expect('cdata', '<x>');
        Observer.Expect('cdata_xml', '<![CDATA[<x>]]>');
        Observer.Expect('empty_inner', '[]');
        Observer.Expect('empty_xml', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure InnerXml_Attributes_Namespaces()
    var
        E: XmlElement;
    begin
        Load('<a xmlns="urn:d"><b x="1" xmlns:p="urn:p"><p:c/></b></a>', E);
        Observer.Observe('a_inner', E.InnerXml());
        Observer.Observe('a_out', Str(E));
        Observer.Expect('a_inner', '<b x="1" xmlns:p="urn:p" xmlns="urn:d"><p:c /></b>');
        Observer.Expect('a_out', '<a xmlns="urn:d">\r\n  <b x="1" xmlns:p="urn:p">\r\n    <p:c />\r\n  </b>\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Names_Prefixed()
    var
        E: XmlElement;
        Child: XmlElement;
        Kids: XmlNodeList;
        N: XmlNode;
    begin
        Load('<p:a xmlns:p="urn:p" xmlns="urn:d"><b/><p:c/></p:a>', E);
        Observer.Observe('name', E.Name());
        Observer.Observe('local', E.LocalName());
        Observer.Observe('ns', E.NamespaceUri());
        Kids := E.GetChildElements();
        Kids.Get(1, N);
        Child := N.AsXmlElement();
        Observer.Observe('b_name', Child.Name());
        Observer.Observe('b_ns', Child.NamespaceUri());
        Kids.Get(2, N);
        Child := N.AsXmlElement();
        Observer.Observe('c_name', Child.Name());
        Observer.Observe('c_local', Child.LocalName());
        Observer.Observe('c_ns', Child.NamespaceUri());
        Observer.Expect('name', 'p:a');
        Observer.Expect('local', 'a');
        Observer.Expect('ns', 'urn:p');
        Observer.Expect('b_name', ':b');
        Observer.Expect('b_ns', 'urn:d');
        Observer.Expect('c_name', 'p:c');
        Observer.Expect('c_local', 'c');
        Observer.Expect('c_ns', 'urn:p');
        Observer.Verify();
    end;

    [Test]
    procedure Navigation_Children()
    var
        E: XmlElement;
        L: XmlNodeList;
        N: XmlNode;
    begin
        Load('<a><b/>t<c><d/></c><!--x--><b/></a>', E);
        L := E.GetChildNodes();
        Observer.Observe('child_nodes', Format(L.Count()));
        L := E.GetChildElements();
        Observer.Observe('child_elems', Format(L.Count()));
        L := E.GetChildElements('b');
        Observer.Observe('child_b', Format(L.Count()));
        L := E.GetChildElements('d');
        Observer.Observe('child_d', Format(L.Count()));
        L := E.GetChildElements('B');
        Observer.Observe('child_B_case', Format(L.Count()));
        L := E.GetDescendantElements();
        Observer.Observe('desc_elems', Format(L.Count()));
        L := E.GetDescendantElements('d');
        Observer.Observe('desc_d', Format(L.Count()));
        L := E.GetDescendantElements('b');
        Observer.Observe('desc_b', Format(L.Count()));
        L := E.GetDescendantNodes();
        Observer.Observe('desc_nodes', Format(L.Count()));
        L.Get(1, N);
        Observer.Observe('first_desc_isel', Format(N.IsXmlElement()));
        L.Get(2, N);
        Observer.Observe('second_desc_istext', Format(N.IsXmlText()));
        Observer.Observe('has_elements', Format(E.HasElements()));
        Observer.Expect('child_nodes', '5');
        Observer.Expect('child_elems', '3');
        Observer.Expect('child_b', '2');
        Observer.Expect('child_d', '0');
        Observer.Expect('child_B_case', '0');
        Observer.Expect('desc_elems', '4');
        Observer.Expect('desc_d', '1');
        Observer.Expect('desc_b', '2');
        Observer.Expect('desc_nodes', '6');
        Observer.Expect('first_desc_isel', 'Yes');
        Observer.Expect('second_desc_istext', 'Yes');
        Observer.Expect('has_elements', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Navigation_Children_Namespaced()
    var
        E: XmlElement;
        L: XmlNodeList;
    begin
        Load('<a xmlns="urn:d" xmlns:p="urn:p"><b/><p:b/><p:c/></a>', E);
        L := E.GetChildElements('b');
        Observer.Observe('b_noNs', Format(L.Count()));
        L := E.GetChildElements('b', 'urn:d');
        Observer.Observe('b_d', Format(L.Count()));
        L := E.GetChildElements('b', 'urn:p');
        Observer.Observe('b_p', Format(L.Count()));
        L := E.GetChildElements('b', '');
        Observer.Observe('b_empty_ns', Format(L.Count()));
        L := E.GetChildElements('c', 'urn:p');
        Observer.Observe('c_p', Format(L.Count()));
        L := E.GetDescendantElements('b', 'urn:p');
        Observer.Observe('desc_b_p', Format(L.Count()));
        L := E.GetDescendantElements('b', 'urn:d');
        Observer.Observe('desc_b_d', Format(L.Count()));
        L := E.GetDescendantElements('b');
        Observer.Observe('desc_b', Format(L.Count()));
        Observer.Expect('b_noNs', '0');
        Observer.Expect('b_d', '1');
        Observer.Expect('b_p', '1');
        Observer.Expect('b_empty_ns', '0');
        Observer.Expect('c_p', '1');
        Observer.Expect('desc_b_p', '1');
        Observer.Expect('desc_b_d', '1');
        Observer.Expect('desc_b', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Navigation_Parent_Document()
    var
        E: XmlElement;
        Child: XmlElement;
        Par: XmlElement;
        Doc: XmlDocument;
        Doc2: XmlDocument;
        L: XmlNodeList;
        N: XmlNode;
        Txt: Text;
    begin
        Load('<a><b><c/></b></a>', E);
        L := E.GetDescendantElements('c');
        L.Get(1, N);
        Child := N.AsXmlElement();
        Observer.Observe('c_parent', Format(Child.GetParent(Par)));
        Observer.Observe('c_parent_name', Par.Name());
        Observer.Observe('b_parent', Format(Par.GetParent(Par)));
        Observer.Observe('a_name', Par.Name());
        Observer.Observe('root_parent', Format(Par.GetParent(Par)));
        Observer.Observe('c_doc', Format(Child.GetDocument(Doc)));
        Doc.WriteTo(Txt);
        Observer.Observe('c_doc_out', Txt);
        E := XmlElement.Create('lone');
        Observer.Observe('lone_parent', Format(E.GetParent(Par)));
        Observer.Observe('lone_doc', Format(E.GetDocument(Doc2)));
        Observer.Expect('c_parent', 'Yes');
        Observer.Expect('c_parent_name', 'b');
        Observer.Expect('b_parent', 'Yes');
        Observer.Expect('a_name', 'a');
        Observer.Expect('root_parent', 'No');
        Observer.Expect('c_doc', 'Yes');
        Observer.Expect('c_doc_out', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <b>\r\n    <c />\r\n  </b>\r\n</a>');
        Observer.Expect('lone_parent', 'No');
        Observer.Expect('lone_doc', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Basic()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlElement.Create('b'));
        E.Add(XmlElement.Create('c'));
        Observer.Observe('add', Str(E));
        E.AddFirst(XmlElement.Create('first'));
        Observer.Observe('addfirst', Str(E));
        E.Add(XmlText.Create('tail'));
        Observer.Observe('addtext', Str(E));
        E.Add(XmlComment.Create('cm'));
        Observer.Observe('addcomment', Str(E));
        E.Add(XmlAttribute.Create('k', 'v'));
        Observer.Observe('addattr', Str(E));
        asserterror E.AddFirst(XmlAttribute.Create('k2', 'v2'));
        Observer.ObserveError('af296');
        Observer.Observe('addfirstattr', Str(E));
        Observer.Expect('add', '<a>\r\n  <b />\r\n  <c />\r\n</a>');
        Observer.Expect('addfirst', '<a>\r\n  <first />\r\n  <b />\r\n  <c />\r\n</a>');
        Observer.Expect('addtext', '<a>\r\n  <first />\r\n  <b />\r\n  <c />tail</a>');
        Observer.Expect('addcomment', '<a>\r\n  <first />\r\n  <b />\r\n  <c />tail<!--cm--></a>');
        Observer.Expect('addattr', '<a k="v">\r\n  <first />\r\n  <b />\r\n  <c />tail<!--cm--></a>');
        Observer.Expect('af296|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        Observer.Expect('af296|code', 'Argument');
        Observer.Expect('addfirstattr', '<a k="v">\r\n  <first />\r\n  <b />\r\n  <c />tail<!--cm--></a>');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Multiple()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlElement.Create('b'), XmlElement.Create('c'), XmlText.Create('t'));
        Observer.Observe('multi', Str(E));
        E.AddFirst(XmlElement.Create('x'), XmlElement.Create('y'));
        Observer.Observe('first_multi', Str(E));
        E.Add('plain text');
        Observer.Observe('text_overload', Str(E));
        Observer.Expect('multi', '<a>\r\n  <b />\r\n  <c />t</a>');
        Observer.Expect('first_multi', '<a>\r\n  <x />\r\n  <y />\r\n  <b />\r\n  <c />t</a>');
        Observer.Expect('text_overload', '<a>\r\n  <x />\r\n  <y />\r\n  <b />\r\n  <c />tplain text</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Add_DuplicateAttribute()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        E.Add(XmlAttribute.Create('k', 'v'));
        asserterror E.Add(XmlAttribute.Create('k', 'w'));
        Observer.ObserveError('dup');
        Observer.Observe('out', Str(E));
        Observer.Expect('dup|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('dup|code', 'InvalidOperation');
        Observer.Expect('out', '<a k="v" />');
        Observer.Verify();
    end;

    [Test]
    procedure Add_AlreadyParented_Node()
    var
        A: XmlElement;
        B: XmlElement;
        C: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
    begin
        Load('<a><c/></a>', A);
        L := A.GetChildElements('c');
        L.Get(1, N);
        C := N.AsXmlElement();
        B := XmlElement.Create('b');
        B.Add(C);
        Observer.Observe('b', Str(B));
        Observer.Observe('a_after', Str(A));
        Observer.Expect('b', '<b>\r\n  <c />\r\n</b>');
        Observer.Expect('a_after', '<a>\r\n  <c />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Self_Error()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('a');
        E.Add(E);
        Observer.Observe('self', 'no error');
        Observer.Observe('out', Str(E));
        Observer.Expect('self', 'no error');
        Observer.Expect('out', '<a>\r\n  <a />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Ancestor_Error()
    var
        A: XmlElement;
        B: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
    begin
        Load('<a><b/></a>', A);
        L := A.GetChildElements('b');
        L.Get(1, N);
        B := N.AsXmlElement();
        B.Add(A);
        Observer.Observe('ancestor', 'no error');
        Observer.Expect('ancestor', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure AddAfterBefore_Self()
    var
        E: XmlElement;
        B: XmlElement;
        C: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
    begin
        Load('<a><b/><c/></a>', E);
        L := E.GetChildElements('b');
        L.Get(1, N);
        B := N.AsXmlElement();
        B.AddAfterSelf(XmlElement.Create('after'));
        Observer.Observe('after', Str(E));
        B.AddBeforeSelf(XmlElement.Create('before'));
        Observer.Observe('before', Str(E));
        B.AddAfterSelf(XmlText.Create('t'));
        Observer.Observe('after_text', Str(E));
        B.AddBeforeSelf(XmlComment.Create('c'));
        Observer.Observe('before_comment', Str(E));
        B.AddAfterSelf(XmlElement.Create('m1'), XmlElement.Create('m2'));
        Observer.Observe('after_multi', Str(E));
        B.AddBeforeSelf(XmlElement.Create('n1'), XmlElement.Create('n2'));
        Observer.Observe('before_multi', Str(E));
        Observer.Expect('after', '<a>\r\n  <b />\r\n  <after />\r\n  <c />\r\n</a>');
        Observer.Expect('before', '<a>\r\n  <before />\r\n  <b />\r\n  <after />\r\n  <c />\r\n</a>');
        Observer.Expect('after_text', '<a>\r\n  <before />\r\n  <b />t<after /><c /></a>');
        Observer.Expect('before_comment', '<a>\r\n  <before />\r\n  <!--c-->\r\n  <b />t<after /><c /></a>');
        Observer.Expect('after_multi', '<a>\r\n  <before />\r\n  <!--c-->\r\n  <b />\r\n  <m1 />\r\n  <m2 />t<after /><c /></a>');
        Observer.Expect('before_multi', '<a>\r\n  <before />\r\n  <!--c-->\r\n  <n1 />\r\n  <n2 />\r\n  <b />\r\n  <m1 />\r\n  <m2 />t<after /><c /></a>');
        Observer.Verify();
    end;

    [Test]
    procedure AddAfterSelf_Root_Error()
    var
        E: XmlElement;
    begin
        Load('<a/>', E);
        asserterror E.AddAfterSelf(XmlElement.Create('b'));
        Observer.ObserveError('root_after_elem');
        asserterror E.AddBeforeSelf(XmlElement.Create('b'));
        Observer.ObserveError('root_before_elem');
        E.AddAfterSelf(XmlComment.Create('c'));
        Observer.Observe('root_after_comment', 'ok');
        E.AddBeforeSelf(XmlComment.Create('c'));
        Observer.Observe('root_before_comment', 'ok');
        E := XmlElement.Create('lone');
        asserterror E.AddAfterSelf(XmlElement.Create('b'));
        Observer.ObserveError('lone_after');
        asserterror E.AddBeforeSelf(XmlElement.Create('b'));
        Observer.ObserveError('lone_before');
        Observer.Expect('root_after_elem|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('root_after_elem|code', 'InvalidOperation');
        Observer.Expect('root_before_elem|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('root_before_elem|code', 'InvalidOperation');
        Observer.Expect('root_after_comment', 'ok');
        Observer.Expect('root_before_comment', 'ok');
        Observer.Expect('lone_after|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('lone_after|code', 'InvalidOperation');
        Observer.Expect('lone_before|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('lone_before|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith()
    var
        E: XmlElement;
        B: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
    begin
        Load('<a><b/><c/></a>', E);
        L := E.GetChildElements('b');
        L.Get(1, N);
        B := N.AsXmlElement();
        B.ReplaceWith(XmlElement.Create('x'));
        Observer.Observe('replace_elem', Str(E));
        Observer.Observe('b_still_name', B.Name());
        Observer.Observe('b_parent', Format(B.GetParent(B)));
        Observer.Expect('replace_elem', '<a>\r\n  <x />\r\n  <c />\r\n</a>');
        Observer.Expect('b_still_name', 'b');
        Observer.Expect('b_parent', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Variants()
    var
        E: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
    begin
        Load('<a><b/><c/><d/></a>', E);
        L := E.GetChildElements('b');
        L.Get(1, N);
        N.AsXmlElement().ReplaceWith(XmlText.Create('t'));
        Observer.Observe('with_text', Str(E));
        L := E.GetChildElements('c');
        L.Get(1, N);
        N.AsXmlElement().ReplaceWith(XmlElement.Create('x'), XmlElement.Create('y'));
        Observer.Observe('with_two', Str(E));
        L := E.GetChildElements('d');
        L.Get(1, N);
        N.AsXmlElement().ReplaceWith(XmlComment.Create('c'));
        Observer.Observe('with_comment', Str(E));
        Observer.Expect('with_text', '<a>t<c /><d /></a>');
        Observer.Expect('with_two', '<a>t<x /><y /><d /></a>');
        Observer.Expect('with_comment', '<a>t<x /><y /><!--c--></a>');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceWith_Root_Unparented()
    var
        E: XmlElement;
    begin
        Load('<a/>', E);
        E.ReplaceWith(XmlElement.Create('b'));
        Observer.Observe('root_replace', Str(E));
        E := XmlElement.Create('lone');
        asserterror E.ReplaceWith(XmlElement.Create('b'));
        Observer.ObserveError('lone');
        Observer.Expect('root_replace', '<a />');
        Observer.Expect('lone|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('lone|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Element()
    var
        E: XmlElement;
        B: XmlElement;
        N: XmlNode;
        L: XmlNodeList;
        Par: XmlElement;
    begin
        Load('<a><b/><c/></a>', E);
        L := E.GetChildElements('b');
        L.Get(1, N);
        B := N.AsXmlElement();
        B.Remove();
        Observer.Observe('after_remove', Str(E));
        Observer.Observe('removed_parent', Format(B.GetParent(Par)));
        Observer.Observe('removed_name', B.Name());
        E.Add(B);
        Observer.Observe('readd', Str(E));
        Observer.Expect('after_remove', '<a>\r\n  <c />\r\n</a>');
        Observer.Expect('removed_parent', 'No');
        Observer.Expect('removed_name', 'b');
        Observer.Expect('readd', '<a>\r\n  <c />\r\n  <b />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Remove_Root_Lone()
    var
        E: XmlElement;
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        XmlDocument.ReadFrom('<a><b/></a>', Doc);
        Doc.GetRoot(Root);
        Root.Remove();
        Observer.Observe('has_root', Format(Doc.GetRoot(E)));
        E := XmlElement.Create('lone');
        asserterror E.Remove();
        Observer.ObserveError('lone_remove');
        Observer.Expect('has_root', 'No');
        Observer.Expect('lone_remove|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('lone_remove|code', 'InvalidOperation');
        Observer.Verify();
    end;

    [Test]
    procedure RemoveNodes()
    var
        E: XmlElement;
    begin
        Load('<a x="1"><b/>t<!--c--></a>', E);
        E.RemoveNodes();
        Observer.Observe('out', Str(E));
        Observer.Observe('has_attr', Format(E.HasAttributes()));
        Observer.Observe('is_empty', Format(E.IsEmpty()));
        E.RemoveNodes();
        Observer.Observe('twice', Str(E));
        E := XmlElement.Create('e');
        E.RemoveNodes();
        Observer.Observe('empty_el', Str(E));
        Observer.Expect('out', '<a x="1" />');
        Observer.Expect('has_attr', 'Yes');
        Observer.Expect('is_empty', 'Yes');
        Observer.Expect('twice', '<a x="1" />');
        Observer.Expect('empty_el', '<e />');
        Observer.Verify();
    end;

    [Test]
    procedure IsEmpty_States()
    var
        E: XmlElement;
    begin
        Load('<a/>', E);
        Observer.Observe('selfclosed', Format(E.IsEmpty()));
        Load('<a></a>', E);
        Observer.Observe('explicit_empty', Format(E.IsEmpty()));
        Load('<a> </a>', E);
        Observer.Observe('space', Format(E.IsEmpty()));
        Load('<a x="1"/>', E);
        Observer.Observe('attr_only', Format(E.IsEmpty()));
        Load('<a><b/></a>', E);
        Observer.Observe('child', Format(E.IsEmpty()));
        Load('<a></a>', E);
        Observer.Observe('explicit_out', Str(E));
        E := XmlElement.Create('x', '', '');
        Observer.Observe('create_empty_text', Str(E));
        Observer.Observe('create_empty_text_isempty', Format(E.IsEmpty()));
        Observer.Expect('selfclosed', 'Yes');
        Observer.Expect('explicit_empty', 'No');
        Observer.Expect('space', 'No');
        Observer.Expect('attr_only', 'Yes');
        Observer.Expect('child', 'No');
        Observer.Expect('explicit_out', '<a></a>');
        Observer.Expect('create_empty_text', '<x></x>');
        Observer.Expect('create_empty_text_isempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReplaceNodes()
    var
        E: XmlElement;
    begin
        Load('<a x="1"><b/></a>', E);
        E.ReplaceNodes(XmlElement.Create('n'));
        Observer.Observe('replace_nodes', Str(E));
        E.ReplaceNodes(XmlText.Create('t'));
        Observer.Observe('replace_text', Str(E));
        E.ReplaceNodes(XmlElement.Create('p'), XmlElement.Create('q'));
        Observer.Observe('replace_two', Str(E));
        Observer.Expect('replace_nodes', '<a x="1">\r\n  <n />\r\n</a>');
        Observer.Expect('replace_text', '<a x="1">t</a>');
        Observer.Expect('replace_two', '<a x="1">\r\n  <p />\r\n  <q />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Element()
    var
        E: XmlElement;
        Txt: Text;
        Opt: XmlWriteOptions;
    begin
        Load('<a><b>1</b></a>', E);
        E.WriteTo(Txt);
        Observer.Observe('plain', Txt);
        Opt.PreserveWhitespace(true);
        E.WriteTo(Opt, Txt);
        Observer.Observe('opt', Txt);
        Load('<a xmlns="urn:d"><b/></a>', E);
        E.WriteTo(Txt);
        Observer.Observe('ns', Txt);
        Observer.Expect('plain', '<a>\r\n  <b>1</b>\r\n</a>');
        Observer.Expect('opt', '<a><b>1</b></a>');
        Observer.Expect('ns', '<a xmlns="urn:d">\r\n  <b />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_Element_OutStream()
    var
        E: XmlElement;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        Load('<a><b/></a>', E);
        TempBlob.CreateOutStream(OutS);
        E.WriteTo(OutS);
        TempBlob.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('out', Txt);
        Observer.Expect('out', 'Ù‹<a>');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Semantics()
    var
        A: XmlElement;
        B: XmlElement;
    begin
        Load('<a><b/></a>', A);
        B := A;
        B.Add(XmlElement.Create('c'));
        Observer.Observe('a_sees_change', Str(A));
        Observer.Observe('b', Str(B));
        Clear(B);
        Observer.Observe('a_after_clear', Str(A));
        Observer.Expect('a_sees_change', '<a>\r\n  <b />\r\n  <c />\r\n</a>');
        Observer.Expect('b', '<a>\r\n  <b />\r\n  <c />\r\n</a>');
        Observer.Expect('a_after_clear', '<a>\r\n  <b />\r\n  <c />\r\n</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Copy_Clone_ViaNode()
    var
        A: XmlElement;
        B: XmlElement;
        N: XmlNode;
        Cl: XmlNode;
    begin
        Load('<a><b/></a>', A);
        N := A.AsXmlNode();
        Observer.Observe('node_out', Format(N.IsXmlElement()));
        B := N.AsXmlElement();
        B.Add(XmlText.Create('t'));
        Observer.Observe('shared', Str(A));
        Observer.Expect('node_out', 'Yes');
        Observer.Expect('shared', '<a>\r\n  <b />t</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Default_Element_Uninitialized()
    var
        E: XmlElement;
        Txt: Text;
    begin
        asserterror Txt := E.Name();
        Observer.ObserveError('name');
        asserterror E.Add(XmlText.Create('x'));
        Observer.ObserveError('add');
        asserterror Txt := E.InnerText();
        Observer.ObserveError('inner');
        asserterror E.WriteTo(Txt);
        Observer.ObserveError('writeto');
        Observer.Expect('name|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('name|code', 'NotInitialized');
        Observer.Expect('add|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('add|code', 'NotInitialized');
        Observer.Expect('inner|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('inner|code', 'NotInitialized');
        Observer.Expect('writeto|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('writeto|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Add_Element_To_Uninitialized_Arg()
    var
        E: XmlElement;
        Child: XmlElement;
    begin
        E := XmlElement.Create('a');
        asserterror E.Add(Child);
        Observer.ObserveError('add_default');
        Observer.Expect('add_default|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlElement variable not initialized.');
        Observer.Expect('add_default|code', 'NotInitialized');
        Observer.Verify();
    end;

    // Corpus issue 671 item 97 (microsoft/AL#5851): in XmlElement.Create(Name, Text) the second text is the namespace URI, also when
    // it is no URI.
    [Test]
    procedure Create_Second_Text_Is_Namespace()
    var
        E: XmlElement;
    begin
        E := XmlElement.Create('name', 'content');
        Observer.Observe('two_texts_out', Str(E));
        Observer.Observe('two_texts_ns', '[' + E.NamespaceUri() + ']');
        Observer.Observe('two_texts_inner', '[' + E.InnerText() + ']');
        E := XmlElement.Create('name', 'content', 'x');
        Observer.Observe('three_texts_out', Str(E));
        E := XmlElement.Create('name', XmlText.Create('content'));
        Observer.Observe('xmltext_out', Str(E));
        Observer.Expect('two_texts_out', '<name xmlns="content" />');
        Observer.Expect('two_texts_ns', '[content]');
        Observer.Expect('two_texts_inner', '[]');
        Observer.Expect('three_texts_out', '<name xmlns="content">x</name>');
        Observer.Expect('xmltext_out', '<name>content</name>');
        Observer.Verify();
    end;

    // Corpus issue 671 item 95 (microsoft/AL#961): XmlNode.AsXmlElement().Add(XmlText) changes the element behind the node.
    [Test]
    procedure AsXmlElement_Add_Text_Via_Node()
    var
        E: XmlElement;
        N: XmlNode;
    begin
        E := XmlElement.Create('e');
        N := E.AsXmlNode();
        N.AsXmlElement().Add(XmlText.Create('x'));
        Observer.Observe('empty_then_add', Str(E) + '|' + E.InnerText());
        Load('<a>old</a>', E);
        N := E.AsXmlNode();
        N.AsXmlElement().Add(XmlText.Create('new'));
        Observer.Observe('text_then_add', Str(E) + '|' + E.InnerText() + '|' + Format(E.GetChildNodes().Count()));
        Observer.Expect('empty_then_add', '<e>x</e>|x');
        Observer.Expect('text_then_add', '<a>oldnew</a>|oldnew|2');
        Observer.Verify();
    end;
}
