// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 73405
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73405 "LT XmT Entities Misc"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure NL(): Text
    var
        Lf: Text[1];
    begin
        Lf[1] := 10;
        exit(Lf);
    end;

    local procedure CR(): Text
    var
        C: Text[1];
    begin
        C[1] := 13;
        exit(C);
    end;

    local procedure Roundtrip(Src: Text): Text
    var
        Doc: XmlDocument;
        Txt: Text;
    begin
        if not XmlDocument.ReadFrom(Src, Doc) then
            exit('ERR:' + GetLastErrorText());
        Doc.WriteTo(Txt);
        exit(Txt);
    end;

    [Test]
    procedure Entities_Predefined()
    begin
        Observer.Observe('lt', Roundtrip('<a>&lt;</a>'));
        Observer.Observe('gt', Roundtrip('<a>&gt;</a>'));
        Observer.Observe('amp', Roundtrip('<a>&amp;</a>'));
        Observer.Observe('quot', Roundtrip('<a>&quot;</a>'));
        Observer.Observe('apos', Roundtrip('<a>&apos;</a>'));
        Observer.Observe('raw_gt', Roundtrip('<a>></a>'));
        Observer.Observe('raw_quote', Roundtrip('<a>"</a>'));
        Observer.Observe('raw_apos', Roundtrip('<a>''</a>'));
        Observer.Observe('attr_gt', Roundtrip('<a k=">"/>'));
        Observer.Observe('attr_quot', Roundtrip('<a k="&quot;"/>'));
        Observer.Observe('attr_apos_single', Roundtrip('<a k=''x"y''/>'));
        Observer.Observe('attr_lt_escaped', Roundtrip('<a k="&lt;"/>'));
        Observer.Expect('lt', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>&lt;</a>');
        Observer.Expect('gt', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>&gt;</a>');
        Observer.Expect('amp', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>&amp;</a>');
        Observer.Expect('quot', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>"</a>');
        Observer.Expect('apos', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>''</a>');
        Observer.Expect('raw_gt', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>&gt;</a>');
        Observer.Expect('raw_quote', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>"</a>');
        Observer.Expect('raw_apos', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>''</a>');
        Observer.Expect('attr_gt', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="&gt;" />');
        Observer.Expect('attr_quot', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="&quot;" />');
        Observer.Expect('attr_apos_single', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="x&quot;y" />');
        Observer.Expect('attr_lt_escaped', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="&lt;" />');
        Observer.Verify();
    end;

    [Test]
    procedure Entities_CharRefs()
    begin
        Observer.Observe('dec', Roundtrip('<a>&#65;</a>'));
        Observer.Observe('hex', Roundtrip('<a>&#x41;</a>'));
        Observer.Observe('euro', Roundtrip('<a>&#8364;</a>'));
        Observer.Observe('nbsp', Roundtrip('<a>&#160;</a>'));
        Observer.Observe('cr', Roundtrip('<a>&#13;</a>'));
        Observer.Observe('lf', Roundtrip('<a>&#10;</a>'));
        Observer.Observe('tab', Roundtrip('<a>&#9;</a>'));
        Observer.Observe('nul', Roundtrip('<a>&#0;</a>'));
        Observer.Observe('ctrl1', Roundtrip('<a>&#1;</a>'));
        Observer.Observe('emoji', Roundtrip('<a>&#128512;</a>'));
        Observer.Observe('too_big', Roundtrip('<a>&#1114112;</a>'));
        Observer.Observe('bad_ref', Roundtrip('<a>&#xZZ;</a>'));
        Observer.Observe('no_semicolon', Roundtrip('<a>&amp</a>'));
        Observer.Observe('lone_amp', Roundtrip('<a>&</a>'));
        Observer.Expect('dec', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>A</a>');
        Observer.Expect('hex', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>A</a>');
        Observer.Expect('euro', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>€</a>');
        Observer.Expect('nbsp', '<?xml version="1.0" encoding="utf-16"?>\r\n<a> </a>');
        Observer.Expect('cr', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n</a>');
        Observer.Expect('lf', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n</a>');
        Observer.Expect('tab', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\t</a>');
        Observer.Expect('nul', 'ERR:The following exception was encountered when processing XML data: ''''.'', hexadecimal value 0x00, is an invalid character. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('ctrl1', 'ERR:The following exception was encountered when processing XML data: ''''\u0001'', hexadecimal value 0x01, is an invalid character. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('emoji', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\uD83D\uDE00</a>');
        Observer.Expect('too_big', 'ERR:The following exception was encountered when processing XML data: ''''\uDC00'', hexadecimal value 0xDC00, is an invalid character. Line 1, position 6.'' at line 1 and position 6.');
        Observer.Expect('bad_ref', 'ERR:The following exception was encountered when processing XML data: ''Invalid syntax for a hexadecimal numeric entity reference. Line 1, position 7.'' at line 1 and position 7.');
        Observer.Expect('no_semicolon', 'ERR:The following exception was encountered when processing XML data: ''''<'' is an unexpected token. The expected token is '';''. Line 1, position 8.'' at line 1 and position 8.');
        Observer.Expect('lone_amp', 'ERR:The following exception was encountered when processing XML data: ''An error occurred while parsing EntityName. Line 1, position 5.'' at line 1 and position 5.');
        Observer.Verify();
    end;

    [Test]
    procedure Entities_Doctype()
    begin
        Observer.Observe('internal_entity', Roundtrip('<!DOCTYPE a [<!ENTITY e "val">]><a>&e;</a>'));
        Observer.Observe('doctype_simple', Roundtrip('<!DOCTYPE a><a/>'));
        Observer.Observe('external_entity', Roundtrip('<!DOCTYPE a [<!ENTITY e SYSTEM "file:///etc/hostname">]><a>&e;</a>'));
        Observer.Observe('doctype_system', Roundtrip('<!DOCTYPE a SYSTEM "http://localhost/x.dtd"><a/>'));
        Observer.Expect('internal_entity', 'ERR:The following exception was encountered when processing XML data: ''Reference to undeclared entity ''e''. Line 1, position 37.'' at line 1 and position 37.');
        Observer.Expect('doctype_simple', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('external_entity', 'ERR:The following exception was encountered when processing XML data: ''Reference to undeclared entity ''e''. Line 1, position 61.'' at line 1 and position 61.');
        Observer.Expect('doctype_system', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure CData_Handling()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        N: XmlNode;
    begin
        Observer.Observe('cdata_roundtrip', Roundtrip('<a><![CDATA[<b>&amp;</b>]]></a>'));
        Observer.Observe('empty_cdata', Roundtrip('<a><![CDATA[]]></a>'));
        Observer.Observe('cdata_with_text', Roundtrip('<a>x<![CDATA[y]]>z</a>'));
        Observer.Observe('cdata_ws', Roundtrip('<a><![CDATA[ ' + NL() + ' ]]></a>'));
        XmlDocument.ReadFrom('<a><![CDATA[v]]></a>', Doc);
        Doc.GetRoot(Root);
        foreach N in Root.GetChildNodes() do begin
            Observer.Observe('is_cdata', Format(N.IsXmlCData()));
            Observer.Observe('is_text', Format(N.IsXmlText()));
        end;
        Observer.Expect('cdata_roundtrip', '<?xml version="1.0" encoding="utf-16"?>\r\n<a><![CDATA[<b>&amp;</b>]]></a>');
        Observer.Expect('empty_cdata', '<?xml version="1.0" encoding="utf-16"?>\r\n<a><![CDATA[]]></a>');
        Observer.Expect('cdata_with_text', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>x<![CDATA[y]]>z</a>');
        Observer.Expect('cdata_ws', '<?xml version="1.0" encoding="utf-16"?>\r\n<a><![CDATA[ \r\n ]]></a>');
        Observer.Expect('is_cdata', 'Yes');
        Observer.Expect('is_text', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Comments_And_PI_Roundtrip()
    begin
        Observer.Observe('comment', Roundtrip('<a><!-- hi --></a>'));
        Observer.Observe('empty_comment', Roundtrip('<a><!----></a>'));
        Observer.Observe('pi', Roundtrip('<a><?t d?></a>'));
        Observer.Observe('pi_nodata', Roundtrip('<a><?t?></a>'));
        Observer.Observe('pi_spaces', Roundtrip('<a><?t   d  ?></a>'));
        Observer.Observe('top_comment', Roundtrip('<!--c--><a/>'));
        Observer.Observe('after_comment', Roundtrip('<a/><!--c-->'));
        Observer.Observe('top_pi', Roundtrip('<?t d?><a/>'));
        Observer.Observe('bad_comment', Roundtrip('<a><!-- a -- b --></a>'));
        Observer.Observe('stylesheet_pi', Roundtrip('<?xml-stylesheet href="s.xsl"?><a/>'));
        Observer.Expect('comment', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <!-- hi -->\r\n</a>');
        Observer.Expect('empty_comment', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <!---->\r\n</a>');
        Observer.Expect('pi', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <?t d?>\r\n</a>');
        Observer.Expect('pi_nodata', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <?t?>\r\n</a>');
        Observer.Expect('pi_spaces', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>\r\n  <?t d  ?>\r\n</a>');
        Observer.Expect('top_comment', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--c-->\r\n<a />');
        Observer.Expect('after_comment', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />\r\n<!--c-->');
        Observer.Expect('top_pi', '<?xml version="1.0" encoding="utf-16"?>\r\n<?t d?>\r\n<a />');
        Observer.Expect('bad_comment', 'ERR:The following exception was encountered when processing XML data: ''An XML comment cannot contain ''--'', and ''-'' cannot be the last character. Line 1, position 11.'' at line 1 and position 11.');
        Observer.Expect('stylesheet_pi', '<?xml version="1.0" encoding="utf-16"?>\r\n<?xml-stylesheet href="s.xsl"?>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Serialization_Forms()
    begin
        Observer.Observe('selfclose', Roundtrip('<a/>'));
        Observer.Observe('selfclose_space', Roundtrip('<a />'));
        Observer.Observe('empty_pair', Roundtrip('<a></a>'));
        Observer.Observe('attr_single_quote', Roundtrip('<a k=''v''/>'));
        Observer.Observe('attr_spaces', Roundtrip('<a   k = "v"   />'));
        Observer.Observe('attr_order', Roundtrip('<a z="1" a="2"/>'));
        Observer.Observe('tag_ws', Roundtrip('<a ' + NL() + 'k="v"' + NL() + '/>'));
        Observer.Observe('trailing_ws', Roundtrip('<a/>' + NL()));
        Observer.Observe('leading_ws', Roundtrip(NL() + '<a/>'));
        Observer.Observe('crlf_text', Roundtrip('<a>x' + CR() + NL() + 'y</a>'));
        Observer.Expect('selfclose', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('selfclose_space', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('empty_pair', '<?xml version="1.0" encoding="utf-16"?>\r\n<a></a>');
        Observer.Expect('attr_single_quote', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="v" />');
        Observer.Expect('attr_spaces', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="v" />');
        Observer.Expect('attr_order', '<?xml version="1.0" encoding="utf-16"?>\r\n<a z="1" a="2" />');
        Observer.Expect('tag_ws', '<?xml version="1.0" encoding="utf-16"?>\r\n<a k="v" />');
        Observer.Expect('trailing_ws', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />\r\n');
        Observer.Expect('leading_ws', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('crlf_text', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>x\r\ny</a>');
        Observer.Verify();
    end;

    [Test]
    procedure Declaration_Roundtrip()
    begin
        Observer.Observe('utf8', Roundtrip('<?xml version="1.0" encoding="utf-8"?><a/>'));
        Observer.Observe('utf8_upper', Roundtrip('<?xml version="1.0" encoding="UTF-8"?><a/>'));
        Observer.Observe('utf16', Roundtrip('<?xml version="1.0" encoding="utf-16"?><a/>'));
        Observer.Observe('latin1', Roundtrip('<?xml version="1.0" encoding="iso-8859-1"?><a/>'));
        Observer.Observe('standalone', Roundtrip('<?xml version="1.0" standalone="yes"?><a/>'));
        Observer.Observe('only_version', Roundtrip('<?xml version="1.0"?><a/>'));
        Observer.Observe('single_quotes', Roundtrip('<?xml version=''1.0''?><a/>'));
        Observer.Observe('with_nl', Roundtrip('<?xml version="1.0"?>' + NL() + '<a/>'));
        Observer.Observe('bom_char', Roundtrip(Format(CreateBom()) + '<a/>'));
        Observer.Expect('utf8', '<?xml version="1.0" encoding="utf-8"?>\r\n<a />');
        Observer.Expect('utf8_upper', '<?xml version="1.0" encoding="UTF-8"?>\r\n<a />');
        Observer.Expect('utf16', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('latin1', '<?xml version="1.0" encoding="iso-8859-1"?>\r\n<a />');
        Observer.Expect('standalone', '<?xml version="1.0" encoding="utf-16" standalone="yes"?>\r\n<a />');
        Observer.Expect('only_version', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('single_quotes', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('with_nl', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('bom_char', 'ERR:The following exception was encountered when processing XML data: ''Data at the root level is invalid. Line 1, position 1.'' at line 1 and position 1.');
        Observer.Verify();
    end;

    local procedure CreateBom(): Text
    var
        C: Text[1];
    begin
        C[1] := 65279;
        exit(C);
    end;

    [Test]
    procedure Unicode_Content()
    var
        Doc: XmlDocument;
        Root: XmlElement;
    begin
        Observer.Observe('umlaut', Roundtrip('<a>äöüß</a>'));
        Observer.Observe('cjk', Roundtrip('<a>日本語</a>'));
        Observer.Observe('unicode_name', Roundtrip('<ä/>'));
        Observer.Observe('unicode_attr', Roundtrip('<a ä="ö"/>'));
        XmlDocument.ReadFrom('<a>日本語</a>', Doc);
        Doc.GetRoot(Root);
        Observer.Observe('len', Format(StrLen(Root.InnerText())));
        Observer.Expect('umlaut', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>äöüß</a>');
        Observer.Expect('cjk', '<?xml version="1.0" encoding="utf-16"?>\r\n<a>日本語</a>');
        Observer.Expect('unicode_name', '<?xml version="1.0" encoding="utf-16"?>\r\n<ä />');
        Observer.Expect('unicode_attr', '<?xml version="1.0" encoding="utf-16"?>\r\n<a ä="ö" />');
        Observer.Expect('len', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Large_And_Deep()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Src: Text;
        i: Integer;
        Txt: Text;
    begin
        for i := 1 to 200 do
            Src += '<n>';
        for i := 1 to 200 do
            Src += '</n>';
        Observer.Observe('deep_200', Format(XmlDocument.ReadFrom(Src, Doc)));
        Src := '<a>';
        for i := 1 to 2000 do
            Src += '<b>' + Format(i) + '</b>';
        Src += '</a>';
        XmlDocument.ReadFrom(Src, Doc);
        Doc.GetRoot(Root);
        Observer.Observe('wide_count', Format(Root.GetChildElements().Count()));
        Doc.WriteTo(Txt);
        Observer.Observe('wide_len', Format(StrLen(Txt)));
        Observer.Expect('deep_200', 'Yes');
        Observer.Expect('wide_count', '2000');
        Observer.Expect('wide_len', '28943');
        Observer.Verify();
    end;

    [Test]
    procedure Document_Level_Navigation()
    var
        Doc: XmlDocument;
        L: XmlNodeList;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0"?><!--c--><a><b><c/></b>t</a>', Doc);
        L := Doc.GetChildNodes();
        Observer.Observe('child_nodes', Format(L.Count()));
        L := Doc.GetChildElements();
        Observer.Observe('child_elements', Format(L.Count()));
        L := Doc.GetChildElements('a');
        Observer.Observe('child_elements_a', Format(L.Count()));
        L := Doc.GetChildElements('b');
        Observer.Observe('child_elements_b', Format(L.Count()));
        L := Doc.GetDescendantElements();
        Observer.Observe('desc_elements', Format(L.Count()));
        L := Doc.GetDescendantElements('c');
        Observer.Observe('desc_c', Format(L.Count()));
        L := Doc.GetDescendantNodes();
        Observer.Observe('desc_nodes', Format(L.Count()));
        Observer.Expect('child_nodes', '2');
        Observer.Expect('child_elements', '1');
        Observer.Expect('child_elements_a', '1');
        Observer.Expect('child_elements_b', '0');
        Observer.Expect('desc_elements', '3');
        Observer.Expect('desc_c', '1');
        Observer.Expect('desc_nodes', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Document_AddFirst_And_Replace()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Doc.GetRoot(Root);
        Root.ReplaceWith(XmlElement.Create('b'));
        Doc.WriteTo(Txt);
        Observer.Observe('replaced_root', Txt);
        Doc.GetRoot(Root);
        Observer.Observe('new_root', Root.Name());
        Doc.RemoveNodes();
        asserterror Doc.WriteTo(Txt);
        Observer.ObserveError('af246');
        Observer.Observe('after_removenodes', '[' + Txt + ']');
        Observer.Observe('has_root', Format(Doc.GetRoot(Root)));
        Observer.Expect('replaced_root', '<?xml version="1.0" encoding="utf-16"?>\r\n<b />');
        Observer.Expect('new_root', 'b');
        Observer.Expect('af246|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af246|code', 'InvalidOperation');
        Observer.Expect('after_removenodes', '[<?xml version="1.0" encoding="utf-16"?>\r\n<b />]');
        Observer.Expect('has_root', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Document_ReplaceNodes()
    var
        Doc: XmlDocument;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Doc.ReplaceNodes(XmlElement.Create('z'));
        Doc.WriteTo(Txt);
        Observer.Observe('replaced', Txt);
        Doc.ReplaceNodes(XmlComment.Create('c'), XmlElement.Create('y'));
        Doc.WriteTo(Txt);
        Observer.Observe('two', Txt);
        Observer.Expect('replaced', '<?xml version="1.0" encoding="utf-16"?>\r\n<z />');
        Observer.Expect('two', '<?xml version="1.0" encoding="utf-16"?>\r\n<!--c-->\r\n<y />');
        Observer.Verify();
    end;

    [Test]
    procedure Document_DocumentType()
    var
        Doc: XmlDocument;
        Dt: XmlDocumentType;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<!DOCTYPE a><a/>', Doc);
        Observer.Observe('has', Format(Doc.GetDocumentType(Dt)));
        XmlDocument.ReadFrom('<a/>', Doc);
        Observer.Observe('none', Format(Doc.GetDocumentType(Dt)));
        Dt := XmlDocumentType.Create('a', '', '', '');
        Doc := XmlDocument.Create(Dt);
        Doc.Add(XmlElement.Create('a'));
        Doc.WriteTo(Txt);
        Observer.Observe('set', Txt);
        Observer.Expect('has', 'No');
        Observer.Expect('none', 'No');
        Observer.Expect('set', '<?xml version="1.0" encoding="utf-16"?>\r\n<!DOCTYPE a PUBLIC "" ""[]>\r\n<a />');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Of_XmlTypes()
    var
        Doc: XmlDocument;
        E: XmlElement;
    begin
        XmlDocument.ReadFrom('<a/>', Doc);
        Doc.GetRoot(E);
        Observer.Observe('format_doc', Format(Doc));
        Observer.Observe('format_elem', Format(E));
        Observer.Observe('format_attr', Format(XmlAttribute.Create('k', 'v')));
        Observer.Observe('format_text', Format(XmlText.Create('t')));
        Observer.Expect('format_doc', '<?xml version="1.0" encoding="utf-16"?>\r\n<a />');
        Observer.Expect('format_elem', '<a />');
        Observer.Expect('format_attr', 'k="v"');
        Observer.Expect('format_text', 't');
        Observer.Verify();
    end;

    [Test]
    procedure Format_Of_Uninitialized()
    var
        Doc: XmlDocument;
        E: XmlElement;
        N: XmlNode;
    begin
        asserterror Observer.Observe('doc', '[' + Format(Doc) + ']');
        Observer.ObserveError('af310');
        asserterror Observer.Observe('elem', '[' + Format(E) + ']');
        Observer.ObserveError('af312');
        asserterror Observer.Observe('node', '[' + Format(N) + ']');
        Observer.ObserveError('af314');
        Observer.Expect('af310|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('af310|code', 'InvalidOperation');
        Observer.Expect('af312|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('af312|code', 'NotInitialized');
        Observer.Expect('af314|text', 'Microsoft.Dynamics.Nav.Runtime.NavXmlNode variable not initialized.');
        Observer.Expect('af314|code', 'NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure Uninitialized_Document_Use()
    var
        Doc: XmlDocument;
        Txt: Text;
        L: XmlNodeList;
    begin
        asserterror Doc.WriteTo(Txt);
        Observer.ObserveError('writeto');
        Doc.SelectNodes('/a', L);
        Observer.Observe('select', 'no error');
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('add', 'no error');
        Observer.Expect('writeto|text', 'The requested operation cannot be performed in this context.');
        Observer.Expect('writeto|code', 'InvalidOperation');
        Observer.Expect('select', 'no error');
        Observer.Expect('add', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Text_Encoding_Stream_Utf16()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Txt: Text;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-16"?><a>ä</a>', Doc);
        TempBlob.CreateOutStream(OutS);
        Doc.WriteTo(OutS);
        Observer.Observe('len', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        InS.ReadText(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('len', '100');
        Observer.Expect('text', ' þ<');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_InStream_Latin1_Bytes()
    var
        Doc: XmlDocument;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Root: XmlElement;
    begin
        TempBlob.CreateOutStream(OutS, TextEncoding::Windows);
        OutS.WriteText('<?xml version="1.0" encoding="iso-8859-1"?><a>ä</a>');
        TempBlob.CreateInStream(InS, TextEncoding::Windows);
        Observer.Observe('ok', Format(XmlDocument.ReadFrom(InS, Doc)));
        Doc.GetRoot(Root);
        Observer.Observe('text', Root.InnerText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('text', 'ä');
        Observer.Verify();
    end;
}
