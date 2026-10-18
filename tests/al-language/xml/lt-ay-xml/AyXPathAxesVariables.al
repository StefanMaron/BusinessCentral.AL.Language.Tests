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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
