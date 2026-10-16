// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: XmlDeclaration Version, Encoding, Standalone getters and setters, WriteTo, GetDeclaration, SetDeclaration
// BC versions: 29 (27 and 28 by CI)

codeunit 72083 "LT P83 Declaration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Decl: XmlDeclaration;
        Doc: XmlDocument;

    [TryFunction]
    local procedure TryVersion(V: Text)
    begin
        Decl.Version(V);
    end;

    [TryFunction]
    local procedure TryEncoding(V: Text)
    begin
        Decl.Encoding(V);
    end;

    [TryFunction]
    local procedure TryStandalone(V: Text)
    begin
        Decl.Standalone(V);
    end;

    [TryFunction]
    local procedure TryCreate(V: Text; E: Text; S: Text)
    begin
        Decl := XmlDeclaration.Create(V, E, S);
    end;

    local procedure Members(): Text
    begin
        exit('[' + Decl.Version() + '|' + Decl.Encoding() + '|' + Decl.Standalone() + ']');
    end;

    local procedure Written(): Text
    var
        T: Text;
    begin
        Decl.WriteTo(T);
        exit(T);
    end;

    [Test]
    procedure Setters_Version()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        Observer.Observe('set-1.1', Format(TryVersion('1.1')));
        Observer.ObserveError('set-1.1');
        Observer.Observe('after-1.1', Members());
        Observer.Observe('set-2.0', Format(TryVersion('2.0')));
        Observer.ObserveError('set-2.0');
        Observer.Observe('after-2.0', Members());
        Observer.Observe('set-empty', Format(TryVersion('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('written', Written());
        Observer.Finish();
    end;

    [Test]
    procedure Setters_Encoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        Observer.Observe('set-utf16', Format(TryEncoding('utf-16')));
        Observer.ObserveError('set-utf16');
        Observer.Observe('after-utf16', Members());
        Observer.Observe('set-latin1', Format(TryEncoding('iso-8859-1')));
        Observer.ObserveError('set-latin1');
        Observer.Observe('after-latin1', Members());
        Observer.Observe('set-bogus', Format(TryEncoding('bogus')));
        Observer.ObserveError('set-bogus');
        Observer.Observe('after-bogus', Members());
        Observer.Observe('set-empty', Format(TryEncoding('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('written', Written());
        Observer.Finish();
    end;

    [Test]
    procedure Setters_Standalone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        Observer.Observe('set-no', Format(TryStandalone('no')));
        Observer.ObserveError('set-no');
        Observer.Observe('after-no', Members());
        Observer.Observe('set-maybe', Format(TryStandalone('maybe')));
        Observer.ObserveError('set-maybe');
        Observer.Observe('after-maybe', Members());
        Observer.Observe('set-upper', Format(TryStandalone('YES')));
        Observer.ObserveError('set-upper');
        Observer.Observe('after-upper', Members());
        Observer.Observe('set-empty', Format(TryStandalone('')));
        Observer.ObserveError('set-empty');
        Observer.Observe('after-empty', Members());
        Observer.Observe('written', Written());
        Observer.Finish();
    end;

    [Test]
    procedure WriteTo_AfterSetters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Decl := XmlDeclaration.Create('1.0', '', '');
        Observer.Observe('start', Written());
        Decl.Encoding('utf-8');
        Observer.Observe('encoding', Written());
        Decl.Standalone('no');
        Observer.Observe('standalone', Written());
        Decl.Version('1.1');
        Observer.Observe('version', Written());
        Decl.Encoding('');
        Observer.Observe('encoding-cleared', Written());
        Decl.Standalone('');
        Observer.Observe('standalone-cleared', Written());
        Observer.Finish();
    end;

    [Test]
    procedure Create_InvalidArguments()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('empty-version', Format(TryCreate('', 'utf-8', 'yes')));
        Observer.ObserveError('empty-version');
        Observer.Observe('members-empty-version', Members());
        Observer.Observe('text-version', Format(TryCreate('abc', 'utf-8', 'yes')));
        Observer.ObserveError('text-version');
        Observer.Observe('members-text-version', Members());
        Observer.Observe('spaces', Format(TryCreate(' 1.0 ', ' utf-8 ', ' yes ')));
        Observer.ObserveError('spaces');
        Observer.Observe('members-spaces', Members());
        Observer.Observe('upper', Format(TryCreate('1.0', 'UTF-8', 'YES')));
        Observer.ObserveError('upper');
        Observer.Observe('members-upper', Members());
        Observer.Finish();
    end;

    [Test]
    procedure Document_SetAndGetDeclaration()
    var
        Observer: Codeunit "Probe Observer";
        Got: XmlDeclaration;
        T: Text;
    begin
        Doc := XmlDocument.Create();
        Doc.Add(XmlElement.Create('a'));
        Observer.Observe('get-before', Format(Doc.GetDeclaration(Got)));
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-8', 'yes'));
        Observer.Observe('get-after', Format(Doc.GetDeclaration(Got)));
        Observer.Observe('got', '[' + Got.Version() + '|' + Got.Encoding() + '|' + Got.Standalone() + ']');
        Doc.WriteTo(T);
        Observer.Observe('written', T);
        Doc.SetDeclaration(XmlDeclaration.Create('1.0', 'utf-16', 'no'));
        Doc.GetDeclaration(Got);
        Observer.Observe('replaced', '[' + Got.Version() + '|' + Got.Encoding() + '|' + Got.Standalone() + ']');
        Doc.WriteTo(T);
        Observer.Observe('replaced-written', T);
        Observer.Observe('child-count', Format(Doc.GetChildNodes().Count()));
        Observer.Finish();
    end;

    [Test]
    procedure Document_DeclarationFromRead()
    var
        Observer: Codeunit "Probe Observer";
        Got: XmlDeclaration;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8" standalone="yes"?><a/>', Doc);
        Observer.Observe('full', Format(Doc.GetDeclaration(Got)));
        Observer.Observe('full-members', '[' + Got.Version() + '|' + Got.Encoding() + '|' + Got.Standalone() + ']');
        XmlDocument.ReadFrom('<?xml version="1.0"?><a/>', Doc);
        Observer.Observe('version-only', Format(Doc.GetDeclaration(Got)));
        Observer.Observe('version-only-members', '[' + Got.Version() + '|' + Got.Encoding() + '|' + Got.Standalone() + ']');
        XmlDocument.ReadFrom('<a/>', Doc);
        Observer.Observe('none', Format(Doc.GetDeclaration(Got)));
        XmlDocument.ReadFrom('<?xml version="1.0" standalone="no"?><!DOCTYPE a><a/>', Doc);
        Observer.Observe('standalone-no', Format(Doc.GetDeclaration(Got)));
        Observer.Observe('standalone-no-members', '[' + Got.Version() + '|' + Got.Encoding() + '|' + Got.Standalone() + ']');
        Observer.Finish();
    end;

    [Test]
    procedure Declaration_AsXmlNode_AndTypeTests()
    var
        Observer: Codeunit "Probe Observer";
        N: XmlNode;
        Back: XmlDeclaration;
    begin
        Decl := XmlDeclaration.Create('1.0', 'utf-8', 'yes');
        N := Decl.AsXmlNode();
        Observer.Observe('is-decl', Format(N.IsXmlDeclaration()));
        Observer.Observe('is-element', Format(N.IsXmlElement()));
        Observer.Observe('is-doctype', Format(N.IsXmlDocumentType()));
        Observer.Observe('is-document', Format(N.IsXmlDocument()));
        Observer.Observe('is-attribute', Format(N.IsXmlAttribute()));
        Observer.Observe('is-text', Format(N.IsXmlText()));
        Back := N.AsXmlDeclaration();
        Observer.Observe('back', '[' + Back.Version() + '|' + Back.Encoding() + '|' + Back.Standalone() + ']');
        Observer.Finish();
    end;

    [Test]
    procedure Declaration_UsedInDocumentCreate()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', 'utf-16', 'no'));
        Doc.Add(XmlElement.Create('a'));
        Doc.WriteTo(T);
        Observer.Observe('utf16', T);
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', 'utf-8', ''));
        Doc.Add(XmlElement.Create('a'));
        Doc.WriteTo(T);
        Observer.Observe('utf8-no-standalone', T);
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.0', '', 'yes'));
        Doc.Add(XmlElement.Create('a'));
        Doc.WriteTo(T);
        Observer.Observe('no-encoding', T);
        Doc := XmlDocument.Create(XmlDeclaration.Create('1.1', 'utf-8', 'yes'));
        Doc.Add(XmlElement.Create('a'));
        Doc.WriteTo(T);
        Observer.Observe('version-1.1', T);
        Observer.Finish();
    end;
}
