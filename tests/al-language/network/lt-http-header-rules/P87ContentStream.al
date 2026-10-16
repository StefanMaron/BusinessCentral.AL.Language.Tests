// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/httpcontent/httpcontent-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P87 Helper (codeunit 74228), table 74221
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: WriteFrom of an InStream (Blob field of an own temporary table, OutStream written into a Blob) and the headers around it
// BC versions: 29 (27 and 28 by CI)

codeunit 74226 "LT P87 Content Stream"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P87 Helper";

    local procedure Type(var H: HttpHeaders): Text
    begin
        exit(Helper.DoGet(H, 'Content-Type'));
    end;

    local procedure Read(var C: HttpContent): Text
    var
        T: Text;
        R: Boolean;
    begin
        T := 'preset';
        R := C.ReadAs(T);
        exit(Format(R) + '/' + T);
    end;

    local procedure FillBlob(var Rec: Record "LT P87 Blob" temporary; Txt: Text)
    var
        OutS: OutStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Code := 'B1';
        Rec.Data.CreateOutStream(OutS);
        OutS.WriteText(Txt);
        Rec.Insert();
    end;

    [Test]
    procedure BlobStream_HeaderBeforeWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillBlob(Rec, 'blob text');
        C.GetHeaders(H);
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.WriteFrom(InS);
        Observer.Observe('oldHasA', Helper.DoContains(H, 'X-A'));
        Observer.Observe('oldType', Type(H));
        C.GetHeaders(H2);
        Observer.Observe('newHasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('newKeys', Helper.Keys(H2));
        Observer.Observe('newType', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure BlobStream_HeaderAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillBlob(Rec, 'blob text');
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('type', Type(H));
        Observer.Observe('add', Helper.DoAdd(H, 'X-A', '1'));
        C.GetHeaders(H2);
        Observer.Observe('hasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('read', Read(C));
        Observer.Observe('readAgain', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure EmptyBlobStream()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Code := 'B1';
        Rec.Insert();
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('keys', Helper.Keys(H));
        Observer.Observe('type', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure StreamThenClearThenText()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        H2: HttpHeaders;
        InS: InStream;
    begin
        FillBlob(Rec, 'blob text');
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        C.GetHeaders(H);
        Helper.DoAdd(H, 'X-A', '1');
        C.WriteFrom(InS);
        C.Clear();
        C.WriteFrom('text');
        C.GetHeaders(H2);
        Observer.Observe('hasA', Helper.DoContains(H2, 'X-A'));
        Observer.Observe('keys', Helper.Keys(H2));
        Observer.Observe('type', Type(H2));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;

    [Test]
    procedure OutStreamIntoBlob_ThenContent()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
        InS2: InStream;
        T: Text;
    begin
        FillBlob(Rec, 'line1');
        C.WriteFrom('from content');
        C.GetHeaders(H);
        Observer.Observe('type', Type(H));
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        InS.ReadText(T);
        Observer.Observe('blobText', T);
        Observer.Observe('contentAsStream', Format(C.ReadAs(InS2)));
        InS2.ReadText(T);
        Observer.Observe('streamText', T);
        Observer.Finish();
    end;

    [Test]
    procedure PartiallyReadStream_Headers()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P87 Blob" temporary;
        C: HttpContent;
        H: HttpHeaders;
        InS: InStream;
        Part: Text;
    begin
        FillBlob(Rec, 'abcdefghij');
        Rec.Get('B1');
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(InS);
        InS.ReadText(Part, 3);
        Observer.Observe('part', Part);
        C.WriteFrom(InS);
        C.GetHeaders(H);
        Observer.Observe('type', Type(H));
        Observer.Observe('read', Read(C));
        Observer.Finish();
    end;
}
