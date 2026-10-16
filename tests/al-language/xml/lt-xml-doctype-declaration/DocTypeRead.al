// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocumenttype/xmldocumenttype-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Reading XML with a DOCTYPE, GetDocumentType on the result, WriteTo of the read document
// BC versions: 29 (27 and 28 by CI)

codeunit 72082 "LT P83 DocType Read"
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
    local procedure TryRead(Src: Text)
    begin
        XmlDocument.ReadFrom(Src, Doc);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; Src: Text)
    var
        T: Text;
    begin
        Clear(Doc);
        Clear(Dt);
        Observer.Observe(Name + '-read', Format(TryRead(Src)));
        Observer.ObserveError(Name + '-read');
        if Doc.GetDocumentType(Dt) then
            Observer.Observe(Name + '-type', GName(Dt) + '|' + GPub(Dt) + '|' + GSys(Dt) + '|' + GSub(Dt))
        else
            Observer.Observe(Name + '-type', 'none');
        Doc.WriteTo(T);
        Observer.Observe(Name + '-written', T);
    end;

    [Test]
    procedure Read_SimpleAndSystem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'simple', '<!DOCTYPE a><a/>');
        Probe(Observer, 'system', '<!DOCTYPE a SYSTEM "a.dtd"><a/>');
        Probe(Observer, 'system-apos', '<!DOCTYPE a SYSTEM ''a.dtd''><a/>');
        Observer.Finish();
    end;

    [Test]
    procedure Read_Public()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'public', '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html/>');
        Probe(Observer, 'public-short', '<!DOCTYPE a PUBLIC "p" "s"><a/>');
        Observer.Finish();
    end;

    [Test]
    procedure Read_InternalSubset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'subset-element', '<!DOCTYPE a [<!ELEMENT a EMPTY>]><a/>');
        Probe(Observer, 'subset-entity', '<!DOCTYPE a [<!ENTITY e "v">]><a/>');
        Probe(Observer, 'subset-attlist', '<!DOCTYPE a [<!ELEMENT a EMPTY><!ATTLIST a x CDATA "d">]><a/>');
        Probe(Observer, 'subset-empty', '<!DOCTYPE a []><a/>');
        Observer.Finish();
    end;

    [Test]
    procedure Read_SystemAndSubset()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'system-subset', '<!DOCTYPE a SYSTEM "a.dtd" [<!ELEMENT a EMPTY>]><a/>');
        Probe(Observer, 'public-subset', '<!DOCTYPE a PUBLIC "p" "s" [<!ELEMENT a EMPTY>]><a/>');
        Observer.Finish();
    end;

    [Test]
    procedure Read_WithDeclarationAndComment()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'declaration', '<?xml version="1.0" encoding="utf-8"?><!DOCTYPE a><a/>');
        Probe(Observer, 'comment-before', '<!--c--><!DOCTYPE a><a/>');
        Probe(Observer, 'comment-after', '<!DOCTYPE a><!--c--><a/>');
        Probe(Observer, 'whitespace', '<!DOCTYPE a>' + '   ' + '<a/>');
        Probe(Observer, 'pi', '<?pi x?><!DOCTYPE a><a/>');
        Observer.Finish();
    end;

    [Test]
    procedure Read_Malformed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<!DOCTYPE a<a/>', Doc);
        Observer.ObserveError('unclosed');
        Observer.Observe('unclosed-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<!doctype a><a/>', Doc);
        Observer.ObserveError('lower-case');
        Observer.Observe('lower-case-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<a/><!DOCTYPE a>', Doc);
        Observer.ObserveError('after-root');
        Observer.Observe('after-root-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        XmlDocument.ReadFrom('<!DOCTYPE a><!DOCTYPE b><a/>', Doc);
        Observer.Observe('two', 'no error');
        Observer.Observe('two-type', Format(Doc.GetDocumentType(Dt)));
        Clear(Doc);
        asserterror XmlDocument.ReadFrom('<!DOCTYPE ><a/>', Doc);
        Observer.ObserveError('no-name');
        Observer.Observe('no-name-type', Format(Doc.GetDocumentType(Dt)));
        Observer.Finish();
    end;

    [Test]
    procedure Read_RootMismatch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'mismatch', '<!DOCTYPE b><a/>');
        asserterror Probe(Observer, 'undeclared-entity-use', '<!DOCTYPE a><a>&e;</a>');
        Observer.ObserveError('af147');
        asserterror Probe(Observer, 'entity-use', '<!DOCTYPE a [<!ENTITY e "v">]><a>&e;</a>');
        Observer.ObserveError('af150');
        Observer.Finish();
    end;
}
