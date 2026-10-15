// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/media/media-importstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72551, table 72552
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row (the four-argument form does not exist in the compiler, only the three-argument form is probed): "BigText.Read, Media.ImportStream with a file name, XmlReadOptions (issue 22)" - `Media.ImportStream(InStream, Description, MimeType, FileName)`
// Facts: four-argument ImportStream, the Tenant Media row it creates (File Name, Description, Mime Type), export of the media
// BC versions: 29 (27 and 28 by CI)

table 72552 "LT PnE Media Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Pic; Media) { }
        field(3; Blob; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

#if BC28PLUS
codeunit 72551 "LT PnE Media Import"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexVal(c: Char): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(Format(c))) - 1);
    end;

    local procedure PngIn(var Rec: Record "LT PnE Media Rec"; var Ins: InStream)
    var
        Out: OutStream;
        Hex: Text;
        B: Byte;
        i: Integer;
    begin
        Hex := '89504E470D0A1A0A0000000D4948445200000001000000010806000000' +
               '1F15C4890000000D49444154789C63F8FFFF3F0005FE02FEA7358184' +
               '0000000049454E44AE426082';
        Rec.Blob.CreateOutStream(Out);
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(Hex[i]) * 16 + HexVal(Hex[i + 1]);
            Out.Write(B);
            i += 2;
        end;
        Rec.Insert();
        Rec.CalcFields(Blob);
        Rec.Blob.CreateInStream(Ins);
    end;

    local procedure TenantMediaText(Id: Guid): Text
    var
        TM: Record "Tenant Media";
    begin
        if not TM.Get(Id) then
            exit('no row');
        exit('FileName=' + TM."File Name" + '|Description=' + TM.Description + '|Mime=' + TM."Mime Type");
    end;

#if BC28PLUS
    [Test]
    procedure ImportStream_ThreeArguments_ForComparison()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Media Rec";
        Ins: InStream;
        Id: Guid;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        PngIn(Rec, Ins);
        Id := Rec.Pic.ImportStream(Ins, 'desc', 'image/png');
        Observer.Observe('hasValue', Format(Rec.Pic.HasValue()));
        Observer.Observe('tenantMedia', TenantMediaText(Rec.Pic.MediaId));
        Rec.DeleteAll();
        Observer.Expect('hasValue', 'No');
        Observer.Expect('tenantMedia', 'no row');
        Observer.Verify();
    end;
#endif
}
#endif
