// Observe-only probes (writer A). Rows: XML WriteTo shape, whitespace, adjacent text, add parent copy/share, root/parent,
// XPath, ReadFrom invalid, DocumentType, ReadFrom(InStream).
codeunit 69802 "PA Xml Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Vis(T: Text): Text
    var
        Lf: Text;
        Cr: Text;
        Tb: Text;
    begin
        Lf[1] := 10;
        Cr[1] := 13;
        Tb[1] := 9;
        T := T.Replace(Cr, '<CR>');
        T := T.Replace(Lf, '<LF>');
        T := T.Replace(Tb, '<TAB>');
        exit(T);
    end;

    local procedure Written(Doc: XmlDocument): Text
    var
        T: Text;
    begin
        Doc.WriteTo(T);
        exit(Vis(T));
    end;

    [Test]
    procedure WriteTo_DeclarationAndIndent()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Child: XmlElement;
        Grand: XmlElement;
    begin
        Doc := XmlDocument.Create();
        Root := XmlElement.Create('root');
        Child := XmlElement.Create('child');
        Grand := XmlElement.Create('grand');
        Child.Add(Grand);
        Root.Add(Child);
        Root.Add(XmlElement.Create('empty'));
        Doc.Add(Root);
        O.Observe('no_declaration', Written(Doc));
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        O.Observe('declaration_utf8_yes', Written(Doc));
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-16', ''));
        O.Observe('declaration_utf16_no_standalone', Written(Doc));
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', '', 'no'));
        O.Observe('declaration_no_encoding', Written(Doc));
        O.Expect('no_declaration', '<?xml version="1.0" encoding="utf-16"?><CR><LF><root><CR><LF>  <child><CR><LF>    <grand /><CR><LF>  </child><CR><LF>  <empty /><CR><LF></root>');
        O.Expect('declaration_utf8_yes', '<?xml version="1.0" encoding="utf-8" standalone="yes"?><CR><LF><root><CR><LF>  <child><CR><LF>    <grand /><CR><LF>  </child><CR><LF>  <empty /><CR><LF></root>');
        O.Expect('declaration_utf16_no_standalone', '<?xml version="1.0" encoding="utf-16" standalone=""?><CR><LF><root><CR><LF>  <child><CR><LF>    <grand /><CR><LF>  </child><CR><LF>  <empty /><CR><LF></root>');
        O.Expect('declaration_no_encoding', '<?xml version="1.0" encoding="" standalone="no"?><CR><LF><root><CR><LF>  <child><CR><LF>    <grand /><CR><LF>  </child><CR><LF>  <empty /><CR><LF></root>');
        O.Verify();
    end;

    [Test]
    procedure WriteTo_TextAndMixedContent()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        E1: XmlElement;
        E2: XmlElement;
        E3: XmlElement;
    begin
        Root := XmlElement.Create('root');
        E1 := XmlElement.Create('withtext');
        E1.Add(XmlText.Create('hello'));
        E2 := XmlElement.Create('withcdata');
        E2.Add(XmlCData.Create('<raw>&'));
        E3 := XmlElement.Create('withws');
        E3.Add(XmlText.Create('  '));
        Root.Add(E1);
        Root.Add(E2);
        Root.Add(E3);
        Root.Add(XmlComment.Create('note'));
        Root.Add(XmlProcessingInstruction.Create('pi', 'data'));
        Doc.Add(Root);
        O.Observe('mixed', Written(Doc));
        E1.Add(XmlElement.Create('inner'));
        O.Observe('text_then_element_child', Written(Doc));
        O.Expect('mixed', '<?xml version="1.0" encoding="utf-16"?><CR><LF><root><CR><LF>  <withtext>hello</withtext><CR><LF>  <withcdata><![CDATA[<raw>&]]></withcdata><CR><LF>  <withws>  </withws><CR><LF>  <!--note--><CR><LF>  <?pi data?><CR><LF></root>');
        O.Expect('text_then_element_child', '<?xml version="1.0" encoding="utf-16"?><CR><LF><root><CR><LF>  <withtext>hello<inner /></withtext><CR><LF>  <withcdata><![CDATA[<raw>&]]></withcdata><CR><LF>  <withws>  </withws><CR><LF>  <!--note--><CR><LF>  <?pi data?><CR><LF></root>');
        O.Verify();
    end;

    [Test]
    procedure WriteTo_EscapesAndAttributes()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Tb: Text;
        Lf: Text;
    begin
        Tb[1] := 9;
        Lf[1] := 10;
        Root := XmlElement.Create('root');
        Root.SetAttribute('q', 'a"b<c>d&e''f');
        Root.SetAttribute('ctl', 'x' + Tb + 'y' + Lf + 'z');
        Root.SetAttribute('empty', '');
        Root.Add(XmlText.Create('t<>&"''' + Tb + Lf + 'end'));
        Doc.Add(Root);
        O.Observe('escaped', Written(Doc));
        O.Observe('innerxml', Vis(Root.InnerXml()));
        O.Observe('outerxml_via_writeto', Written(Doc));
        O.Expect('escaped', '<?xml version="1.0" encoding="utf-16"?><CR><LF><root q="a&quot;b&lt;c&gt;d&amp;e''f" ctl="x&#x9;y&#xA;z" empty="">t&lt;&gt;&amp;"''<TAB><CR><LF>end</root>');
        O.Expect('innerxml', 't&lt;&gt;&amp;"''<TAB><LF>end');
        O.Expect('outerxml_via_writeto', '<?xml version="1.0" encoding="utf-16"?><CR><LF><root q="a&quot;b&lt;c&gt;d&amp;e''f" ctl="x&#x9;y&#xA;z" empty="">t&lt;&gt;&amp;"''<TAB><CR><LF>end</root>');
        O.Verify();
    end;

    [Test]
    procedure WriteTo_EmptyElementFromParsedText()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        XmlDocument.ReadFrom('<a></a>', Doc);
        O.Observe('parsed_a_open_close', Written(Doc));
        XmlDocument.ReadFrom('<a/>', Doc);
        O.Observe('parsed_a_selfclose', Written(Doc));
        XmlDocument.ReadFrom('<a><b></b><c/><d> </d></a>', Doc);
        O.Observe('parsed_nested_empty_forms', Written(Doc));
        O.Expect('parsed_a_open_close', '<?xml version="1.0" encoding="utf-16"?><CR><LF><a></a>');
        O.Expect('parsed_a_selfclose', '<?xml version="1.0" encoding="utf-16"?><CR><LF><a />');
        O.Expect('parsed_nested_empty_forms', '<?xml version="1.0" encoding="utf-16"?><CR><LF><a><CR><LF>  <b></b><CR><LF>  <c /><CR><LF>  <d> </d><CR><LF></a>');
        O.Verify();
    end;

    [Test]
    procedure Whitespace_PreservedInAndOutsideRoot()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Nodes: XmlNodeList;
        Lf: Text;
    begin
        Lf[1] := 10;
        XmlDocument.ReadFrom(Lf + '  <r>' + Lf + '    <a>x</a>' + Lf + '  </r>' + Lf, Doc);
        Doc.GetRoot(Root);
        O.Observe('written', Written(Doc));
        Nodes := Doc.GetChildNodes();
        O.Observe('doc_childnodes_count', Format(Nodes.Count()));
        Nodes := Root.GetChildNodes();
        O.Observe('root_childnodes_count', Format(Nodes.Count()));
        O.Observe('root_innerxml', Vis(Root.InnerXml()));
        O.Observe('root_innertext', Vis(Root.InnerText()));
        O.Expect('written', '<?xml version="1.0" encoding="utf-16"?><CR><LF>  <r><CR><LF>    <a>x</a><CR><LF>  </r><CR><LF>');
        O.Expect('doc_childnodes_count', '3');
        O.Expect('root_childnodes_count', '3');
        O.Expect('root_innerxml', '<LF>    <a>x</a><LF>  ');
        O.Expect('root_innertext', '<LF>    x<LF>  ');
        O.Verify();
    end;

    [Test]
    procedure AdjacentTextNodes_NotMerged()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        Root := XmlElement.Create('r');
        Root.Add('a');
        Root.Add(XmlText.Create('b'));
        Root.Add('c');
        Doc.Add(Root);
        O.Observe('children_count', Format(Root.GetChildNodes().Count()));
        O.Observe('written', Written(Doc));
        O.Observe('innertext', Root.InnerText());
        O.Expect('children_count', '2');
        O.Expect('written', '<?xml version="1.0" encoding="utf-16"?><CR><LF><r>abc</r>');
        O.Expect('innertext', 'abc');
        O.Verify();
    end;

    [Test]
    procedure Add_NodeWithParent_CopyOrShare()
    var
        O: Codeunit "Probe Observer";
        D1: XmlDocument;
        D2: XmlDocument;
        R1: XmlElement;
        R2: XmlElement;
        C: XmlElement;
        Nodes: XmlNodeList;
        N: XmlNode;
    begin
        R1 := XmlElement.Create('r1');
        R2 := XmlElement.Create('r2');
        C := XmlElement.Create('c');
        R1.Add(C);
        R2.Add(C);
        C.SetAttribute('late', '1');
        D1.Add(R1);
        D2.Add(R2);
        O.Observe('d1_after_second_add', Written(D1));
        O.Observe('d2_after_second_add', Written(D2));
        O.Observe('r1_children', Format(R1.GetChildNodes().Count()));
        R1.GetChildNodes().Get(1, N);
        N.AsXmlElement().SetAttribute('viaparent', '1');
        O.Observe('d1_after_parent_side_change', Written(D1));
        O.Observe('d2_after_parent_side_change', Written(D2));
        O.Expect('d1_after_second_add', '<?xml version="1.0" encoding="utf-16"?><CR><LF><r1><CR><LF>  <c late="1" /><CR><LF></r1>');
        O.Expect('d2_after_second_add', '<?xml version="1.0" encoding="utf-16"?><CR><LF><r2><CR><LF>  <c /><CR><LF></r2>');
        O.Expect('r1_children', '1');
        O.Expect('d1_after_parent_side_change', '<?xml version="1.0" encoding="utf-16"?><CR><LF><r1><CR><LF>  <c late="1" viaparent="1" /><CR><LF></r1>');
        O.Expect('d2_after_parent_side_change', '<?xml version="1.0" encoding="utf-16"?><CR><LF><r2><CR><LF>  <c /><CR><LF></r2>');
        O.Verify();
    end;

    [Test]
    procedure Add_SecondRoot_Error()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
    begin
        Doc.Add(XmlElement.Create('a'));
        asserterror Doc.Add(XmlElement.Create('b'));
        O.ObserveError('second_root');
        O.Expect('second_root|text', 'The requested operation cannot be performed in this context.');
        O.Expect('second_root|code', 'InvalidOperation');
        O.Verify();
    end;

    [Test]
    procedure Add_AttributeTwice_Error()
    var
        O: Codeunit "Probe Observer";
        E: XmlElement;
        A: XmlAttribute;
    begin
        E := XmlElement.Create('e');
        E.Add(XmlAttribute.Create('x', '1'));
        asserterror E.Add(XmlAttribute.Create('x', '2'));
        O.ObserveError('same_attribute_name_twice');
        A := XmlAttribute.Create('y', '1');
        E.Add(A);
        asserterror E.Add(A);
        O.ObserveError('same_attribute_instance_twice');
        O.Expect('same_attribute_name_twice|text', 'The requested operation cannot be performed in this context.');
        O.Expect('same_attribute_name_twice|code', 'InvalidOperation');
        O.Expect('same_attribute_instance_twice|text', 'The requested operation cannot be performed in this context.');
        O.Expect('same_attribute_instance_twice|code', 'InvalidOperation');
        O.Verify();
    end;

    [Test]
    procedure Add_NodeIntoWrongContainer_Error()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Doc2: XmlDocument;
        E: XmlElement;
    begin
        E := XmlElement.Create('e');
        asserterror E.Add(XmlDocument.Create());
        O.ObserveError('document_into_element_via_add_node');
        Doc.Add(XmlElement.Create('r'));
        asserterror Doc.Add(XmlText.Create('text at doc level'));
        O.ObserveError('text_into_document_with_root');
        asserterror Doc.Add(XmlAttribute.Create('a', 'b'));
        O.ObserveError('attribute_into_document');
        O.Expect('document_into_element_via_add_node|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        O.Expect('document_into_element_via_add_node|code', 'Argument');
        O.Expect('text_into_document_with_root|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        O.Expect('text_into_document_with_root|code', 'Argument');
        O.Expect('attribute_into_document|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        O.Expect('attribute_into_document|code', 'Argument');
        O.Verify();
    end;

    [Test]
    procedure GetParent_RootAndDetached_ResultUsed()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Detached: XmlElement;
        P: XmlElement;
        D: XmlDocument;
        Ns: Text;
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:p"><c/></r>', Doc);
        Doc.GetRoot(Root);
        O.Observe('root_getparent', Format(Root.GetParent(P)));
        Detached := XmlElement.Create('d');
        O.Observe('detached_getdocument', Format(Detached.GetDocument(D)));
        O.Observe('root_getdocument', Format(Root.GetDocument(D)));
        O.Observe('ns_of_prefix_p', Format(Root.GetNamespaceOfPrefix('p', Ns)) + ' ' + Ns);
        O.Observe('ns_of_prefix_unknown', Format(Root.GetNamespaceOfPrefix('zz', Ns)) + ' ' + Ns);
        O.Observe('ns_of_prefix_empty', Format(Root.GetNamespaceOfPrefix('', Ns)) + ' ' + Ns);
        O.Expect('root_getparent', 'No');
        O.Expect('detached_getdocument', 'No');
        O.Expect('root_getdocument', 'Yes');
        O.Expect('ns_of_prefix_p', 'Yes urn:p');
        O.Expect('ns_of_prefix_unknown', 'No urn:p');
        O.Expect('ns_of_prefix_empty', 'No urn:p');
        O.Verify();
    end;

    [Test]
    procedure GetParent_Root_Statement()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        P: XmlElement;
    begin
        XmlDocument.ReadFrom('<r/>', Doc);
        Doc.GetRoot(Root);
        asserterror Root.GetParent(P);
        O.ObserveError('root_getparent_statement');
        O.Expect('root_getparent_statement|text', 'The XML node is not set.');
        O.Expect('root_getparent_statement|code', 'XmlNodeNotFound');
        O.Verify();
    end;

    [Test]
    procedure GetDocument_Detached_Statement()
    var
        O: Codeunit "Probe Observer";
        E: XmlElement;
        D: XmlDocument;
    begin
        E := XmlElement.Create('d');
        asserterror E.GetDocument(D);
        O.ObserveError('detached_getdocument_statement');
        O.Expect('detached_getdocument_statement|text', 'The XML node is not set.');
        O.Expect('detached_getdocument_statement|code', 'XmlNodeNotFound');
        O.Verify();
    end;

    [Test]
    procedure GetNamespaceOfPrefix_Empty_Statement()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Root: XmlElement;
        Ns: Text;
    begin
        XmlDocument.ReadFrom('<r xmlns="urn:def"/>', Doc);
        Doc.GetRoot(Root);
        asserterror Root.GetNamespaceOfPrefix('', Ns);
        O.ObserveError('empty_prefix_statement');
        O.Observe('ns_after', Ns);
        O.Observe('namespace_uri', Root.NamespaceUri());
        asserterror Root.GetNamespaceOfPrefix('nope', Ns);
        O.ObserveError('unknown_prefix_statement');
        O.Expect('empty_prefix_statement|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        O.Expect('empty_prefix_statement|code', 'Argument');
        O.Expect('ns_after', '');
        O.Expect('namespace_uri', 'urn:def');
        O.Expect('unknown_prefix_statement|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLArgumentException'' was thrown.');
        O.Expect('unknown_prefix_statement|code', 'Argument');
        O.Verify();
    end;

    [Test]
    procedure XPath_CountsForPaths()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Paths: List of [Text];
        P: Text;
    begin
        XmlDocument.ReadFrom('<r a="1"><x a="v">t1</x><x a="w">t2</x><y><x a="v">t3</x></y><z/>tail</r>', Doc);
        Paths.Add('/r');
        Paths.Add('/r/*');
        Paths.Add('/r/x');
        Paths.Add('//x');
        Paths.Add('/r/x[1]');
        Paths.Add('/r/x[last()]');
        Paths.Add('/r/x[@a=''v'']');
        Paths.Add('//x[@a=''v'']');
        Paths.Add('/r/@a');
        Paths.Add('/r/x/text()');
        Paths.Add('/r/text()');
        Paths.Add('/r/y/..');
        Paths.Add('/r/.');
        Paths.Add('//*[local-name()=''x'']');
        Paths.Add('/r/x[0]');
        Paths.Add('/r/x[position()=2]');
        Paths.Add('/r/x[2]/@a');
        Paths.Add('/r/following-sibling::z');
        Paths.Add('/r/x | /r/z');
        Paths.Add('/r/x[text()=''t2'']');
        Paths.Add('count(/r/x)');
        Paths.Add('/r/x/..');
        Paths.Add('//comment()');
        Paths.Add('//node()');
        foreach P in Paths do
            O.Observe('xpath_[' + P + ']', XPathCount(Doc, P));
        O.Expect('xpath_[/r]', 'count=1 r');
        O.Expect('xpath_[/r/*]', 'count=4 x');
        O.Expect('xpath_[/r/x]', 'count=2 x');
        O.Expect('xpath_[//x]', 'count=3 x');
        O.Expect('xpath_[/r/x[1]]', 'count=1 x');
        O.Expect('xpath_[/r/x[last()]]', 'count=1 x');
        O.Expect('xpath_[/r/x[@a=''v'']]', 'count=1 x');
        O.Expect('xpath_[//x[@a=''v'']]', 'count=2 x');
        O.Expect('xpath_[/r/@a]', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute to Microsoft.Dynamics.Nav.Runtime.NavXmlElement./Conversion');
        O.Expect('xpath_[/r/x/text()]', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlText to Microsoft.Dynamics.Nav.Runtime.NavXmlElement./Conversion');
        O.Expect('xpath_[/r/text()]', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlText to Microsoft.Dynamics.Nav.Runtime.NavXmlElement./Conversion');
        O.Expect('xpath_[/r/y/..]', 'count=1 r');
        O.Expect('xpath_[/r/.]', 'count=1 r');
        O.Expect('xpath_[//*[local-name()=''x'']]', 'count=3 x');
        O.Expect('xpath_[/r/x[0]]', 'count=0');
        O.Expect('xpath_[/r/x[position()=2]]', 'count=1 x');
        O.Expect('xpath_[/r/x[2]/@a]', 'ERR:Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavXmlAttribute to Microsoft.Dynamics.Nav.Runtime.NavXmlElement./Conversion');
        O.Expect('xpath_[/r/following-sibling::z]', 'count=0');
        O.Expect('xpath_[/r/x | /r/z]', 'count=3 x');
        O.Expect('xpath_[/r/x[text()=''t2'']]', 'count=1 x');
        O.Expect('xpath_[count(/r/x)]', 'count=0');
        O.Expect('xpath_[/r/x/..]', 'count=1 r');
        O.Expect('xpath_[//comment()]', 'count=0');
        O.Expect('xpath_[//node()]', 'count=10 r');
        O.Verify();
    end;

    local procedure XPathCount(Doc: XmlDocument; P: Text): Text
    var
        R: Text;
    begin
        if XPathCountF(Doc, P, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure XPathCountF(Doc: XmlDocument; P: Text; var R: Text)
    var
        Nodes: XmlNodeList;
        N: XmlNode;
        I: Integer;
    begin
        if not Doc.SelectNodes(P, Nodes) then begin
            R := 'selectnodes=false';
            exit;
        end;
        R := 'count=' + Format(Nodes.Count());
        for I := 1 to Nodes.Count() do begin
            Nodes.Get(I, N);
            R += ' ' + N.AsXmlElement().Name();
            exit;
        end;
    end;

    [Test]
    procedure XPath_MalformedStatement()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Paths: List of [Text];
        P: Text;
    begin
        XmlDocument.ReadFrom('<r><x/></r>', Doc);
        Paths.Add('/r/@@@');
        Paths.Add('/r[');
        Paths.Add('');
        Paths.Add('//');
        Paths.Add('/r/x[');
        Paths.Add('p:x');
        Paths.Add('/r/p:x');
        Paths.Add('count(');
        Paths.Add('/r/x[1');
        Paths.Add('1+');
        Paths.Add('/r/unknownfunc()');
        Paths.Add('$var');
        foreach P in Paths do
            O.Observe('xpath_error_[' + P + ']', XPathStatement(Doc, P));
        O.Expect('xpath_error_[/r/@@@]', 'no error');
        O.Expect('xpath_error_[/r[]', 'no error');
        O.Expect('xpath_error_[]', 'no error');
        O.Expect('xpath_error_[//]', 'no error');
        O.Expect('xpath_error_[/r/x[]', 'no error');
        O.Expect('xpath_error_[p:x]', 'no error');
        O.Expect('xpath_error_[/r/p:x]', 'no error');
        O.Expect('xpath_error_[count(]', 'no error');
        O.Expect('xpath_error_[/r/x[1]', 'no error');
        O.Expect('xpath_error_[1+]', 'no error');
        O.Expect('xpath_error_[/r/unknownfunc()]', 'no error');
        O.Expect('xpath_error_[$var]', 'no error');
        O.Verify();
    end;

    local procedure XPathStatement(Doc: XmlDocument; P: Text): Text
    var
        Nodes: XmlNodeList;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TrySelect(Doc, P);
        if Ok then
            exit('no error');
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySelect(Doc: XmlDocument; P: Text)
    var
        Nodes: XmlNodeList;
        Ok: Boolean;
    begin
        Ok := Doc.SelectNodes(P, Nodes);
    end;

    [Test]
    procedure XPath_NamespaceManager()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Mgr: XmlNamespaceManager;
        Nodes: XmlNodeList;
        LookedUp: Text;
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:p" xmlns="urn:d"><p:x/><x/></r>', Doc);
        O.Observe('prefixed_without_manager', TryNs(Doc, '/r/p:x', false));
        O.Observe('unprefixed_name_in_default_ns', TryNs(Doc, '/r/x', false));
        Mgr.NameTable(Doc.NameTable());
        Mgr.AddNamespace('p', 'urn:p');
        Mgr.AddNamespace('d', 'urn:d');
        O.Observe('mgr_p_x', TryNsMgr(Doc, '/d:r/p:x', Mgr));
        O.Observe('mgr_d_x', TryNsMgr(Doc, '/d:r/d:x', Mgr));
        O.Observe('mgr_unknown_prefix', TryNsMgr(Doc, '/d:r/q:x', Mgr));
        O.Observe('mgr_lookup_p', Format(Mgr.LookupNamespace('p', LookedUp)) + ' ' + LookedUp);
        O.Observe('mgr_has_p', Format(Mgr.HasNamespace('p')));
        O.Observe('mgr_has_q', Format(Mgr.HasNamespace('q')));
        O.Expect('prefixed_without_manager', 'No count=0');
        O.Expect('unprefixed_name_in_default_ns', 'Yes count=0');
        O.Expect('mgr_p_x', 'Yes count=1');
        O.Expect('mgr_d_x', 'Yes count=1');
        O.Expect('mgr_unknown_prefix', 'No count=0');
        O.Expect('mgr_lookup_p', 'Yes urn:p');
        O.Expect('mgr_has_p', 'Yes');
        O.Expect('mgr_has_q', 'No');
        O.Verify();
    end;

    local procedure TryNs(Doc: XmlDocument; P: Text; Dummy: Boolean): Text
    var
        R: Text;
    begin
        if TryNsF(Doc, P, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNsF(Doc: XmlDocument; P: Text; var R: Text)
    var
        Nodes: XmlNodeList;
        Ok: Boolean;
    begin
        Ok := Doc.SelectNodes(P, Nodes);
        R := Format(Ok) + ' count=' + Format(Nodes.Count());
    end;

    local procedure TryNsMgr(Doc: XmlDocument; P: Text; Mgr: XmlNamespaceManager): Text
    var
        R: Text;
    begin
        if TryNsMgrF(Doc, P, Mgr, R) then
            exit(R);
        exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryNsMgrF(Doc: XmlDocument; P: Text; Mgr: XmlNamespaceManager; var R: Text)
    var
        Nodes: XmlNodeList;
        Ok: Boolean;
    begin
        Ok := Doc.SelectNodes(P, Mgr, Nodes);
        R := Format(Ok) + ' count=' + Format(Nodes.Count());
    end;

    [Test]
    procedure ReadFrom_Invalid_ResultUsed()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Inputs: List of [Text];
        T: Text;
    begin
        Inputs.Add('');
        Inputs.Add('<');
        Inputs.Add('<a>');
        Inputs.Add('<a></b>');
        Inputs.Add('<a b=1/>');
        Inputs.Add('text only');
        Inputs.Add('<a/><b/>');
        Inputs.Add('<?xml version="1.0"?>');
        Inputs.Add('<a>&bogus;</a>');
        Inputs.Add('<a b="1" b="2"/>');
        Inputs.Add('<a xmlns:p="urn:p"><q:x/></a>');
        Inputs.Add('<a><!-- unterminated</a>');
        Inputs.Add('  <a/>');
        Inputs.Add('<a/>  trailing');
        Inputs.Add('<?xml version="9.9"?><a/>');
        Inputs.Add('<?xml version="1.0" encoding="nonsense"?><a/>');
        foreach T in Inputs do
            O.Observe('readfrom_bool_[' + T + ']', Format(XmlDocument.ReadFrom(T, Doc)));
        O.Expect('readfrom_bool_[]', 'No');
        O.Expect('readfrom_bool_[<]', 'No');
        O.Expect('readfrom_bool_[<a>]', 'No');
        O.Expect('readfrom_bool_[<a></b>]', 'No');
        O.Expect('readfrom_bool_[<a b=1/>]', 'No');
        O.Expect('readfrom_bool_[text only]', 'No');
        O.Expect('readfrom_bool_[<a/><b/>]', 'No');
        O.Expect('readfrom_bool_[<?xml version="1.0"?>]', 'No');
        O.Expect('readfrom_bool_[<a>&bogus;</a>]', 'No');
        O.Expect('readfrom_bool_[<a b="1" b="2"/>]', 'No');
        O.Expect('readfrom_bool_[<a xmlns:p="urn:p"><q:x/></a>]', 'No');
        O.Expect('readfrom_bool_[<a><!-- unterminated</a>]', 'No');
        O.Expect('readfrom_bool_[  <a/>]', 'Yes');
        O.Expect('readfrom_bool_[<a/>  trailing]', 'No');
        O.Expect('readfrom_bool_[<?xml version="9.9"?><a/>]', 'No');
        O.Expect('readfrom_bool_[<?xml version="1.0" encoding="nonsense"?><a/>]', 'Yes');
        O.Verify();
    end;

    [Test]
    procedure ReadFrom_Invalid_Statement()
    var
        O: Codeunit "Probe Observer";
        Inputs: List of [Text];
        T: Text;
    begin
        Inputs.Add('');
        Inputs.Add('<');
        Inputs.Add('<a>');
        Inputs.Add('<a></b>');
        Inputs.Add('<a b=1/>');
        Inputs.Add('text only');
        Inputs.Add('<a/><b/>');
        Inputs.Add('<?xml version="1.0"?>');
        Inputs.Add('<a>&bogus;</a>');
        Inputs.Add('<a b="1" b="2"/>');
        Inputs.Add('<a><!-- unterminated</a>');
        Inputs.Add('<a/>  trailing');
        foreach T in Inputs do
            O.Observe('readfrom_stmt_[' + T + ']', ReadStatement(T));
        O.Expect('readfrom_stmt_[]', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0. /Xml:Xml');
        O.Expect('readfrom_stmt_[<]', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a>]', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a></b>]', 'The following exception was encountered when processing XML data: ''The ''a'' start tag on line 1 position 2 does not match the end tag of ''b''. Line 1, position 6.'' at line 1 and position 6. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a b=1/>]', 'The following exception was encountered when processing XML data: ''''1'' is an unexpected token. The expected token is ''"'' or ''''''. Line 1, position 6.'' at line 1 and position 6. /Xml:Xml');
        O.Expect('readfrom_stmt_[text only]', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a/><b/>]', 'The following exception was encountered when processing XML data: ''There are multiple root elements. Line 1, position 6.'' at line 1 and position 6. /Xml:Xml');
        O.Expect('readfrom_stmt_[<?xml version="1.0"?>]', 'The following exception was encountered when processing XML data: ''Root element is missing.'' at line 0 and position 0. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a>&bogus;</a>]', 'The following exception was encountered when processing XML data: ''Reference to undeclared entity ''bogus''. Line 1, position 5.'' at line 1 and position 5. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a b="1" b="2"/>]', 'The following exception was encountered when processing XML data: ''''b'' is a duplicate attribute name. Line 1, position 10.'' at line 1 and position 10. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a><!-- unterminated</a>]', 'The following exception was encountered when processing XML data: ''Unexpected end of file while parsing Comment has occurred. Line 1, position 25.'' at line 1 and position 25. /Xml:Xml');
        O.Expect('readfrom_stmt_[<a/>  trailing]', 'The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 7.'' at line 1 and position 7. /Xml:Xml');
        O.Verify();
    end;





    local procedure ReadStatement(T: Text): Text
    var
        Doc: XmlDocument;
    begin
        ClearLastError();
        asserterror XmlDocument.ReadFrom(T, Doc);
        exit(GetLastErrorText() + ' /' + GetLastErrorCode());
    end;

    [Test]
    procedure DocumentType_WithoutDoctype()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Dt: XmlDocumentType;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        O.Observe('getdocumenttype_bool', Format(Doc.GetDocumentType(Dt)));
        asserterror Doc.GetDocumentType(Dt);
        O.ObserveError('getdocumenttype_statement');
        O.Expect('getdocumenttype_bool', 'No');
        O.Expect('getdocumenttype_statement|text', 'The XML node is not set.');
        O.Expect('getdocumenttype_statement|code', 'XmlNodeNotFound');
        O.Verify();
    end;

    [Test]
    procedure DocumentType_ReadWithDoctype()
    var
        O: Codeunit "Probe Observer";
        Doc: XmlDocument;
        Dt: XmlDocumentType;
        Ok: Boolean;
    begin
        Ok := XmlDocument.ReadFrom('<!DOCTYPE a [<!ELEMENT a EMPTY>]><a/>', Doc);
        O.Observe('readfrom_with_doctype_bool', Format(Ok));
        if Ok then begin
            O.Observe('getdocumenttype_bool', Format(Doc.GetDocumentType(Dt)));
            O.Observe('written', Written(Doc));
        end else
            O.Observe('last_error', GetLastErrorText());
        Ok := XmlDocument.ReadFrom('<!DOCTYPE html><html/>', Doc);
        O.Observe('readfrom_with_simple_doctype_bool', Format(Ok));
        O.Expect('readfrom_with_doctype_bool', 'Yes');
        O.Expect('getdocumenttype_bool', 'No');
        O.Expect('written', '<?xml version="1.0" encoding="utf-16"?><CR><LF><a />');
        O.Expect('readfrom_with_simple_doctype_bool', 'Yes');
        O.Verify();
    end;

    [Test]
    procedure ReadFrom_Stream_Encodings()
    var
        O: Codeunit "Probe Observer";
    begin
        O.Observe('utf8_no_bom', ReadStream(1));
        O.Observe('utf8_with_bom', ReadStream(2));
        O.Observe('utf16_text', ReadStream(3));
        O.Observe('latin1_bytes_declared_utf8', ReadStream(4));
        O.Observe('empty_stream', ReadStream(5));
        O.Observe('utf8_umlaut_content', ReadStream(6));
        O.Expect('utf8_no_bom', 'ok=Yes eos=No root=a text=x');
        O.Expect('utf8_with_bom', 'ok=Yes eos=No root=a text=x');
        O.Expect('utf16_text', 'ok=Yes eos=No root=a text=x');
        O.Expect('latin1_bytes_declared_utf8', 'ok=No eos=No');
        O.Expect('empty_stream', 'ok=No eos=Yes');
        O.Expect('utf8_umlaut_content', 'ok=Yes eos=No root=a text=äö€');
        O.Verify();
    end;

    local procedure ReadStream(Kind: Integer): Text
    var
        Blob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Doc: XmlDocument;
        Root: XmlElement;
        Ok: Boolean;
        Res: Text;
        B: Byte;
    begin
        case Kind of
            1:
                begin
                    Blob.CreateOutStream(OutS, TextEncoding::UTF8);
                    OutS.WriteText('<a>x</a>');
                end;
            2:
                begin
                    Blob.CreateOutStream(OutS);
                    B := 239;
                    OutS.Write(B);
                end;
            3:
                begin
                    Blob.CreateOutStream(OutS, TextEncoding::UTF16);
                    OutS.WriteText('<a>x</a>');
                end;
            4:
                begin
                    Blob.CreateOutStream(OutS, TextEncoding::Windows);
                    OutS.WriteText('<a>' + 'ä' + '</a>');
                end;
            5:
                Blob.CreateOutStream(OutS);
            6:
                begin
                    Blob.CreateOutStream(OutS, TextEncoding::UTF8);
                    OutS.WriteText('<a>äö€</a>');
                end;
        end;
        if Kind = 2 then begin
            B := 187;
            OutS.Write(B);
            B := 191;
            OutS.Write(B);
            OutS.WriteText('<a>x</a>');
        end;
        Blob.CreateInStream(InS);
        if not TryReadDoc(InS, Doc, Ok) then
            exit('ERR:' + GetLastErrorText() + '/' + GetLastErrorCode());
        Res := 'ok=' + Format(Ok) + ' eos=' + Format(InS.EOS());
        if Ok then begin
            Doc.GetRoot(Root);
            Res += ' root=' + Root.Name() + ' text=' + Root.InnerText();
        end;
        exit(Res);
    end;

    [TryFunction]
    local procedure TryReadDoc(InS: InStream; var Doc: XmlDocument; var Ok: Boolean)
    begin
        Ok := XmlDocument.ReadFrom(InS, Doc);
    end;
}
