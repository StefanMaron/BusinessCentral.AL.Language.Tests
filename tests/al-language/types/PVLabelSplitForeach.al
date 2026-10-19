// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-split-method
// Scope: in-scope
// Probe: written against a real BC 27.5 service tier and run on BC 29.0.54011.55816; every literal below is what those tiers produced.
//
// Label.Split and Text.Split: one separator splits at each occurrence and keeps empty parts ('a,b;c,,d' gives [a][b;c][][d]); several separators split at any of them ([a][b][c][][d]); no
// separator found gives the whole text; an empty label gives one empty part; Split() without a separator splits at white space ('a b  c' gives [a][b][][c]). A Label variable has
// Split like a Text. foreach over a JsonArray visits the tokens in order (value, value, value, null value, object, array: 'V:No V:No V:No V:Yes O A') and an array that grows inside the loop is
// walked as it was at the start (3 elements, one added inside: 3 iterations), an empty array gives none; foreach over an XmlAttributeCollection gives the XmlAttribute
// values in document order (a=1;b=two;c=;). Database.LockTimeoutDuration is positive and Database.LockTimeout is Yes on this container (the exact default is a server setting and not pinned).
// Fixtures used: self-contained codeunit 69341
// BC versions: 27.5, 29.0

codeunit 69341 "PV Label Foreach Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        CsvLbl: Label 'a,b;c,,d', Locked = true;
        OneLbl: Label 'single', Locked = true;
        EmptyLbl: Label '', Locked = true;

    local procedure Join(List: List of [Text]): Text
    var
        Part: Text;
        Result: Text;
    begin
        foreach Part in List do
            Result += '[' + Part + ']';
        exit(Result);
    end;

    [Test]
    procedure Label_Split_OneAndSeveralSeparators()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('one_separator', Join(CsvLbl.Split(',')));
        Observer.Observe('two_separators_list', Join(CsvLbl.Split(',', ';')));
        Observer.Observe('no_separator_found', Join(OneLbl.Split(',')));
        Observer.Observe('empty_label', Join(EmptyLbl.Split(',')));
        Observer.Observe('count_one_separator', Format(CsvLbl.Split(',').Count()));
        Observer.Expect('one_separator', '[a][b;c][][d]');
        Observer.Expect('two_separators_list', '[a][b][c][][d]');
        Observer.Expect('no_separator_found', '[single]');
        Observer.Expect('empty_label', '[]');
        Observer.Expect('count_one_separator', '4');
        Observer.Verify();
    end;

    [Test]
    procedure TextFromLabel_Split()
    var
        T: Text;
        Observer: Codeunit "Probe Observer";
    begin
        T := CsvLbl;
        Observer.Observe('text_one_separator', Join(T.Split(',')));
        Observer.Observe('text_two_separators', Join(T.Split(',', ';')));
        Observer.Observe('text_whitespace_default', Join('a b  c'.Split()));
        Observer.Expect('text_one_separator', '[a][b;c][][d]');
        Observer.Expect('text_two_separators', '[a][b][c][][d]');
        Observer.Expect('text_whitespace_default', '[a][b][][c]');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_JsonArray_ElementsAndOrder()
    var
        Arr: JsonArray;
        Token: JsonToken;
        Seen: Text;
        Observer: Codeunit "Probe Observer";
    begin
        Arr.ReadFrom('[1,"two",true,null,{"k":4},[5]]');
        foreach Token in Arr do begin
            if Token.IsValue() then
                Seen += 'V:' + Format(Token.AsValue().IsNull()) + ' '
            else
                if Token.IsObject() then
                    Seen += 'O '
                else
                    Seen += 'A ';
        end;
        Observer.Observe('kinds_in_order', Seen);
        Observer.Observe('count', Format(Arr.Count()));
        Observer.Expect('kinds_in_order', 'V:No V:No V:No V:Yes O A ');
        Observer.Expect('count', '6');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_JsonArray_Empty_AndNestedModification()
    var
        Arr: JsonArray;
        Token: JsonToken;
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        Arr.ReadFrom('[]');
        foreach Token in Arr do
            Count += 1;
        Observer.Observe('empty_iterations', Format(Count));
        Arr.ReadFrom('[1,2,3]');
        Count := 0;
        foreach Token in Arr do begin
            Count += 1;
            if Count = 1 then
                Arr.Add(4);
        end;
        Observer.Observe('iterations_when_added_inside', Format(Count));
        Observer.Expect('empty_iterations', '0');
        Observer.Expect('iterations_when_added_inside', '3');
        Observer.Verify();
    end;

    [Test]
    procedure Foreach_XmlAttributeCollection()
    var
        Doc: XmlDocument;
        Root: XmlElement;
        Attrs: XmlAttributeCollection;
        Attr: XmlAttribute;
        Seen: Text;
        Count: Integer;
        Observer: Codeunit "Probe Observer";
    begin
        XmlDocument.ReadFrom('<root a="1" b="two" c=""/>', Doc);
        Doc.GetRoot(Root);
        Attrs := Root.Attributes();
        foreach Attr in Attrs do begin
            Seen += Attr.Name() + '=' + Attr.Value() + ';';
            Count += 1;
        end;
        Observer.Observe('attributes_in_order', Seen);
        Observer.Observe('count', Format(Count));
        Observer.Observe('collection_count', Format(Attrs.Count()));
        XmlDocument.ReadFrom('<root/>', Doc);
        Doc.GetRoot(Root);
        Count := 0;
        foreach Attr in Root.Attributes() do
            Count += 1;
        Observer.Observe('no_attributes', Format(Count));
        Observer.Expect('attributes_in_order', 'a=1;b=two;c=;');
        Observer.Expect('count', '3');
        Observer.Expect('collection_count', '3');
        Observer.Expect('no_attributes', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Database_LockTimeoutDuration_Default()
    var
        D: Duration;
        Observer: Codeunit "Probe Observer";
    begin
        D := Database.LockTimeoutDuration();
        Observer.Observe('default_positive', Format(D > 0));
        Observer.Observe('lock_timeout_enabled', Format(Database.LockTimeout()));
        Observer.Expect('default_positive', 'Yes');
        Observer.Expect('lock_timeout_enabled', 'Yes');
        Observer.Verify();
    end;
}
