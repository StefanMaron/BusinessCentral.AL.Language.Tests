// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 74200 "LT StT Rec" (temporary only), self-contained codeunit 85782
// Probe: corpus issue 671 item 60 (microsoft/AL issues 1201, 7172, 7329, 7575, 7990): an InStream returned or passed back from a procedure whose
//   local Temp Blob, local temporary record with a Blob field or local temporary Tenant Media record goes out of scope.
// Facts: what reading the stream gives after the owner is gone (text read, Length, EOS).
// BC versions: 27, 28, 29

codeunit 85782 "LT DC InStream Scope"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure FromTempBlob(Content: Text) Result: InStream
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(Result);
    end;

    local procedure FromTempBlobVar(Content: Text; var InS: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempBlob.CreateInStream(InS);
    end;

    local procedure FromTempRecord(Content: Text) Result: InStream
    var
        TempRec: Record "LT StT Rec" temporary;
        OutS: OutStream;
    begin
        TempRec.Id := 1;
        TempRec.Data.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempRec.Insert();
        TempRec.Data.CreateInStream(Result);
    end;

    local procedure FromTenantMedia(Content: Text) Result: InStream
    var
        TempTenantMedia: Record "Tenant Media" temporary;
        OutS: OutStream;
    begin
        TempTenantMedia.Content.CreateOutStream(OutS);
        OutS.WriteText(Content);
        TempTenantMedia.Content.CreateInStream(Result);
    end;

    local procedure ReadAll(var InS: InStream): Text
    var
        Txt: Text;
    begin
        InS.ReadText(Txt);
        exit(Txt);
    end;

    [Test]
    procedure Item60_InStreamFromLocalTempBlob()
    var
        InS: InStream;
        InS2: InStream;
    begin
        InS := FromTempBlob('hello temp blob');
        Observer.Observe('return_length', Format(InS.Length()));
        Observer.Observe('return_text', ReadAll(InS));
        Observer.Observe('return_eos', Format(InS.EOS()));
        FromTempBlobVar('hello var', InS2);
        Observer.Observe('var_text', ReadAll(InS2));
        InS := FromTempBlob('first');
        InS2 := FromTempBlob('second');
        Observer.Observe('two_first', ReadAll(InS));
        Observer.Observe('two_second', ReadAll(InS2));
        Observer.Finish();
    end;

    [Test]
    procedure Item60_InStreamFromLocalTempRecord()
    var
        InS: InStream;
    begin
        InS := FromTempRecord('hello record');
        Observer.Observe('record_text', ReadAll(InS));
        InS := FromTenantMedia('hello media');
        Observer.Observe('media_text', ReadAll(InS));
        Observer.Finish();
    end;
}
