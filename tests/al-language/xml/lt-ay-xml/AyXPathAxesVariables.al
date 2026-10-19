// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-selectnodes-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80503
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: SelectNodes with every XPath axis (ancestor, ancestor-or-self, descendant, descendant-or-self, following, following-sibling, preceding,
// preceding-sibling, parent, self, attribute, child, namespace), with an XPath variable ($v alone, in a predicate, in a function), and with an
// unclosed function call (in a predicate, nested, at the end of a path): the result, the node names, GetLastErrorText and GetLastErrorCode.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80503 "LT AY XPath Axes Variables"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySelect(Context: XmlElement; Path: Text; var Nodes: XmlNodeList; var Ok: Boolean)
    begin
        Ok := Context.SelectNodes(Path, Nodes);
    end;

    local procedure NodeName(N: XmlNode): Text
    begin
        if N.IsXmlElement() then
            exit(N.AsXmlElement().Name());
        if N.IsXmlAttribute() then
            exit('@' + N.AsXmlAttribute().Name());
        if N.IsXmlText() then
            exit('#text');
        if N.IsXmlDocument() then
            exit('#doc');
        exit('#other');
    end;

    local procedure Q(var Observer: Codeunit "Probe Observer"; Context: XmlElement; ObsKey: Text; Path: Text)
    var
        Nodes: XmlNodeList;
        N: XmlNode;
        Ok: Boolean;
        T: Text;
    begin
        ClearLastError();
        if TrySelect(Context, Path, Nodes, Ok) then begin
            T := Format(Ok) + ' ' + Format(Nodes.Count()) + ':';
            foreach N in Nodes do
                T += NodeName(N) + ',';
            Observer.Observe(ObsKey, T);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure Load(var Root: XmlElement; var Mid: XmlElement)
    var
        Doc: XmlDocument;
        N: XmlNode;
    begin
        XmlDocument.ReadFrom('<r xmlns:p="urn:p"><a id="1"><b id="2"><c id="3"/><d id="4"/></b><e id="5"/></a><f id="6"><g id="7"/></f></r>', Doc);
        Doc.GetRoot(Root);
        Root.SelectSingleNode('//b', N);
        Mid := N.AsXmlElement();
    end;

    [Test]
    procedure XPath_Axes_1()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'ancestor', 'ancestor::*');
        Q(Observer, B, 'ancestor_or_self', 'ancestor-or-self::*');
        Observer.Expect('ancestor', 'Yes 2:r,a,');
        Observer.Expect('ancestor_or_self', 'Yes 3:r,a,b,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_2()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'descendant', 'descendant::*');
        Q(Observer, B, 'descendant_or_self', 'descendant-or-self::*');
        Observer.Expect('descendant', 'Yes 2:c,d,');
        Observer.Expect('descendant_or_self', 'Yes 3:b,c,d,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_3()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'following', 'following::*');
        Q(Observer, B, 'following_sibling', 'following-sibling::*');
        Observer.Expect('following', 'Yes 3:e,f,g,');
        Observer.Expect('following_sibling', 'Yes 1:e,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_4()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'preceding_of_g', '//g/preceding::*');
        Q(Observer, B, 'preceding_sibling_of_e', '//e/preceding-sibling::*');
        Observer.Expect('preceding_of_g', 'Yes 5:a,b,c,d,e,');
        Observer.Expect('preceding_sibling_of_e', 'Yes 1:b,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_5()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'parent', 'parent::*');
        Q(Observer, B, 'self', 'self::b');
        Observer.Expect('parent', 'Yes 1:a,');
        Observer.Expect('self', 'Yes 1:b,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_6()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'self_other', 'self::a');
        Q(Observer, B, 'attribute', 'attribute::*');
        Observer.Expect('self_other', 'Yes 0:');
        Observer.Expect('attribute', 'Yes 1:@id,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_7()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'child', 'child::*');
        Q(Observer, B, 'namespace', 'namespace::*');
        Observer.Expect('child', 'Yes 2:c,d,');
        Observer.Expect('namespace', 'Yes 2:@xmlns:p,@xmlns:xml,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_8()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'ancestor_pos', 'ancestor::*[1]');
        Q(Observer, B, 'preceding_pos', '//g/preceding::*[1]');
        Observer.Expect('ancestor_pos', 'Yes 1:a,');
        Observer.Expect('preceding_pos', 'Yes 1:e,');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Axes_9()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, B, 'unknown_axis', 'sideways::*');
        Observer.Expect('unknown_axis', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Variables_1()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'var_alone', '$v');
        Q(Observer, Root, 'var_in_predicate', '//*[@id=$v]');
        Observer.Expect('var_alone', 'No 0:');
        Observer.Expect('var_in_predicate', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_Variables_2()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'var_in_function', '//*[contains(@id, $v)]');
        Q(Observer, Root, 'var_dollar_only', '//*[@id=$]');
        Observer.Expect('var_in_function', 'No 0:');
        Observer.Expect('var_dollar_only', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_UnclosedCalls_1()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'unclosed_in_predicate', '//*[contains(@id, ''1'']');
        Q(Observer, Root, 'unclosed_nested', '//*[not(contains(@id, ''1'')]');
        Observer.Expect('unclosed_in_predicate', 'No 0:');
        Observer.Expect('unclosed_nested', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_UnclosedCalls_2()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'unclosed_at_end', '//*[last(]');
        Q(Observer, Root, 'unclosed_path_end', '//a/text(');
        Observer.Expect('unclosed_at_end', 'No 0:');
        Observer.Expect('unclosed_path_end', 'No 0:');
        Observer.Verify();
    end;

    [Test]
    procedure XPath_UnclosedCalls_3()
    var
        Observer: Codeunit "Probe Observer";
        Root: XmlElement;
        B: XmlElement;
    begin
        Load(Root, B);
        Q(Observer, Root, 'unclosed_name', '//*[local-name(=''a'']');
        Observer.Expect('unclosed_name', 'No 0:');
        Observer.Verify();
    end;
}
