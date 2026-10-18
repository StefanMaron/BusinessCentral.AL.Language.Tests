// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/xmldocument/xmldocument-readfrom-instream-xmldocument-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80500
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: XmlDocument.ReadFrom(InStream, var XmlDocument) over raw bytes: UTF-16 LE and BE with a byte order mark, UTF-16 LE without one, UTF-16 with an
// encoding declaration (utf-16 and a contradicting utf-8), a UTF-8 byte order mark, bytes that are not valid UTF-8 (in text, in an attribute, with a
// utf-8 declaration) and ISO-8859-1 bytes with their declaration: the result, the root text, the error text and code, and InStream.EOS afterwards.
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80500 "LT AY Xml ReadFrom Stream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRead(var InS: InStream; var Doc: XmlDocument)
    begin
        XmlDocument.ReadFrom(InS, Doc);
    end;

    local procedure ReadBytes(var Observer: Codeunit "Probe Observer"; Name: Text; Bytes64: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Base64: Codeunit "Base64 Convert";
        OutS: OutStream;
        InS: InStream;
        Doc: XmlDocument;
        Root: XmlElement;
        Attr: XmlAttribute;
        Ok: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        Base64.FromBase64(Bytes64, OutS);
        TempBlob.CreateInStream(InS);
        ClearLastError();
        Ok := TryRead(InS, Doc);
        Observer.Observe(Name + '_ok', Format(Ok));
        if Ok then begin
            if Doc.GetRoot(Root) then begin
                Observer.Observe(Name + '_root', Root.Name() + '=' + Root.InnerText());
                if Root.Attributes().Get('x', Attr) then
                    Observer.Observe(Name + '_attr', Attr.Value());
            end else
                Observer.Observe(Name + '_root', '<none>');
        end else
            Observer.ObserveError(Name);
        Observer.Observe(Name + '_eos', Format(InS.EOS()));
    end;

    [Test]
    procedure ReadFrom_le_bom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r>aé</r> as UTF-16 LE with a byte order mark
        ReadBytes(Observer, 'le_bom', '//48AHIAPgBhAOkAPAAvAHIAPgA=');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_be_bom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r>aé</r> as UTF-16 BE with a byte order mark
        ReadBytes(Observer, 'be_bom', '/v8APAByAD4AYQDpADwALwByAD4=');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_le_nobom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r>aé</r> as UTF-16 LE without a byte order mark
        ReadBytes(Observer, 'le_nobom', 'PAByAD4AYQDpADwALwByAD4A');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_le_bom_decl16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // UTF-16 LE with a byte order mark and encoding="utf-16"
        ReadBytes(Observer, 'le_bom_decl16', '//48AD8AeABtAGwAIAB2AGUAcgBzAGkAbwBuAD0AIgAxAC4AMAAiACAAZQBuAGMAbwBkAGkAbgBnAD0AIgB1AHQAZgAtADEANgAiAD8APgA8AHIAPgBhAOkAPAAvAHIAPgA=');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_le_bom_decl8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // UTF-16 LE with a byte order mark and encoding="utf-8"
        ReadBytes(Observer, 'le_bom_decl8', '//48AD8AeABtAGwAIAB2AGUAcgBzAGkAbwBuAD0AIgAxAC4AMAAiACAAZQBuAGMAbwBkAGkAbgBnAD0AIgB1AHQAZgAtADgAIgA/AD4APAByAD4AYQDpADwALwByAD4A');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_utf8_bom()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r>aé</r> as UTF-8 with a byte order mark
        ReadBytes(Observer, 'utf8_bom', '77u/PHI+YcOpPC9yPg==');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_bad_ff()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r>a 0xFF b</r>
        ReadBytes(Observer, 'bad_ff', 'PHI+Yf9iPC9yPg==');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_bad_cont()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r> 0xC3 0x28 </r> (a lead byte followed by a byte that is no continuation byte)
        ReadBytes(Observer, 'bad_cont', 'PHI+wyg8L3I+');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_bad_decl8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <?xml ... encoding="utf-8"?><r>a 0xFF b</r>
        ReadBytes(Observer, 'bad_decl8', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48cj5h/2I8L3I+');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_bad_attr()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <r x=" 0x80 "/>
        ReadBytes(Observer, 'bad_attr', 'PHIgeD0igCIvPg==');
        Observer.Finish();
    end;

    [Test]
    procedure ReadFrom_latin1_decl()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // <?xml ... encoding="iso-8859-1"?><r>a 0xE9</r>
        ReadBytes(Observer, 'latin1_decl', 'PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iaXNvLTg4NTktMSI/PjxyPmHpPC9yPg==');
        Observer.Finish();
    end;
}
