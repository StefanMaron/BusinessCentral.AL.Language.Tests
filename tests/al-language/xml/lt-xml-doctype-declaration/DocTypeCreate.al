// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDocumentType.Create overloads and the getters Name, PublicId, SystemId, InternalSubset
// BC versions: 29 (27 and 28 by CI)

codeunit 72079 "LT P83 DocType Create"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
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
    local procedure TryCreate(N: Text; P: Text; S: Text; I: Text)
    begin
        Dt := XmlDocumentType.Create(N, P, S, I);
    end;

    [TryFunction]
    local procedure TryCreate1(N: Text)
    begin
        Dt := XmlDocumentType.Create(N);
    end;

    [TryFunction]
    local procedure TryCreate3(N: Text; P: Text; S: Text)
    begin
        Dt := XmlDocumentType.Create(N, P, S);
    end;

    local procedure Members(): Text
    begin
        exit('[' + GName(Dt) + '|' + GPub(Dt) + '|' + GSys(Dt) + '|' + GSub(Dt) + ']');
    end;

    [Test]
    procedure Create_FourArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dt := XmlDocumentType.Create('html', '-//W3C//DTD XHTML 1.0 Strict//EN', 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd', '<!ENTITY e "v">');
        Observer.Observe('all', Members());
        Dt := XmlDocumentType.Create('a', '', '', '');
        Observer.Observe('empty', Members());
        Dt := XmlDocumentType.Create('a', 'p', '', '');
        Observer.Observe('public-only', Members());
        Dt := XmlDocumentType.Create('a', '', 's', '');
        Observer.Observe('system-only', Members());
        Dt := XmlDocumentType.Create('a', '', '', 'x');
        Observer.Observe('subset-only', Members());
        Dt := XmlDocumentType.Create('a', 'p', 's', '');
        Observer.Observe('public-system', Members());
        Dt := XmlDocumentType.Create('a', 'p', '', 'x');
        Observer.Observe('public-subset', Members());
        Dt := XmlDocumentType.Create('a', '', 's', 'x');
        Observer.Observe('system-subset', Members());
        Observer.Finish();
    end;

    [Test]
    procedure Create_NameOnly()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create1', Format(TryCreate1('html')));
        Observer.ObserveError('create1');
        if Format(TryCreate1('html')) = 'Yes' then
            asserterror Observer.Observe('members1', Members());
            Observer.ObserveError('af103');
        Observer.Observe('create1-empty', Format(TryCreate1('')));
        Observer.ObserveError('create1-empty');
        Observer.Finish();
    end;

    [Test]
    procedure Create_ThreeArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('create3', Format(TryCreate3('html', 'p', 's')));
        Observer.ObserveError('create3');
        if Format(TryCreate3('html', 'p', 's')) = 'Yes' then
            asserterror Observer.Observe('members3', Members());
            Observer.ObserveError('af118');
        Observer.Finish();
    end;

    [Test]
    procedure Create_NamesWithSpecialCharacters()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
        N: Text;
        i: Integer;
    begin
        Names.Add('a');
        Names.Add('a-b');
        Names.Add('a.b');
        Names.Add('_a');
        Names.Add('a:b');
        Names.Add('äöü');
        i := 0;
        foreach N in Names do begin
            i += 1;
            Observer.Observe('ok' + Format(i), Format(TryCreate(N, '', '', '')));
            Observer.ObserveError('ok' + Format(i));
            if GName(Dt) <> '' then
                Observer.Observe('name' + Format(i), GName(Dt));
            Clear(Dt);
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Create_LongValues()
    var
        Observer: Codeunit "Probe Observer";
        Long: Text;
        i: Integer;
    begin
        for i := 1 to 2000 do
            Long += 'a';
        Observer.Observe('long-name', Format(TryCreate(Long, '', '', '')));
        Observer.ObserveError('long-name');
        if GName(Dt) <> '' then
            Observer.Observe('long-name-length', Format(StrLen(GName(Dt))));
        Observer.Observe('long-subset', Format(TryCreate('a', '', '', Long)));
        Observer.ObserveError('long-subset');
        Observer.Observe('long-subset-length', Format(StrLen(GSub(Dt))));
        Observer.Observe('long-public', Format(TryCreate('a', Long, '', '')));
        Observer.ObserveError('long-public');
        Observer.Observe('long-public-length', Format(StrLen(GPub(Dt))));
        Observer.Observe('long-system', Format(TryCreate('a', '', Long, '')));
        Observer.ObserveError('long-system');
        Observer.Observe('long-system-length', Format(StrLen(GSys(Dt))));
        Observer.Finish();
    end;

    [Test]
    procedure Create_UnicodeAndMarkupInValues()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('unicode', Format(TryCreate('a', 'Grüße €', 'Straße ü', 'ä')));
        Observer.ObserveError('unicode');
        Observer.Observe('unicode-members', Members());
        Observer.Observe('quotes', Format(TryCreate('a', 'p"q', 's"t', '')));
        Observer.ObserveError('quotes');
        Observer.Observe('quotes-members', Members());
        Observer.Observe('apostrophes', Format(TryCreate('a', 'p''q', 's''t', '')));
        Observer.ObserveError('apostrophes');
        Observer.Observe('apostrophes-members', Members());
        Observer.Observe('markup', Format(TryCreate('a', '<p>', '<s>', '<!ELEMENT a (#PCDATA)>')));
        Observer.ObserveError('markup');
        Observer.Observe('markup-members', Members());
        Observer.Observe('whitespace', Format(TryCreate('a', ' p ', ' s ', ' x ')));
        Observer.ObserveError('whitespace');
        Observer.Observe('whitespace-members', Members());
        Observer.Finish();
    end;

    [Test]
    procedure Create_ProducesIndependentObjects()
    var
        Observer: Codeunit "Probe Observer";
        Dt2: XmlDocumentType;
    begin
        Dt := XmlDocumentType.Create('a', 'p', 's', 'i');
        Dt2 := XmlDocumentType.Create('b', 'q', 't', 'j');
        Observer.Observe('first', Members());
        Dt.SetName('changed');
        Observer.Observe('second-name', GName(Dt2));
        Observer.Observe('first-name', GName(Dt));
        Observer.Finish();
    end;
}
