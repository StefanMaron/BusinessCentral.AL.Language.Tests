// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPF Media Row (69933), TPF Media Card (69933), TPF Row (69932), TPF Card (69932), Assert (60021)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: a Media control with a media imported shows the media's id, and a MediaSet
// control shows the id of the FIRST media in the set, not the set's own id (MediaId()); both are
// lowercase with hyphens and no braces. Measured on a probe revision on every cloud leg, 27.0 to
// 29.0 (a set of one media). The ids are random per run, so the expectation is what the record
// itself reports.

codeunit 69934 "TPF Media Filled Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    [Test]
    procedure Value_Media_ShowsTheMediaId()
    var
        Row: Record "TPF Media Row";
        Card: TestPage "TPF Media Card";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(ValidPngBase64, OutStr);
        TempBlob.CreateInStream(InStr);
        Row.One.ImportStream(InStr, 'one');
        TempBlob.CreateInStream(InStr);
        Row.Pic.ImportStream(InStr, 'pic');
        Row.Modify();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Assert.AreEqual(IdText(Row.One.MediaId()), Card.One.Value(), 'Media');
        Assert.AreEqual(IdText(Row.Pic.Item(1)), Card.Pic.Value(), 'MediaSet');
        Assert.AreNotEqual(IdText(Row.Pic.MediaId()), Card.Pic.Value(), 'the MediaSet text is not the set id');
        Card.Close();
    end;


    [Test]
    procedure Probe_DateWrites()
    var
        Obs: Text;
    begin
        Obs += W(20240101D) + W(20240102D) + W(20240111D) + W(20240112D) + W(20240201D) + W(20240215D);
        Obs += W(20241101D) + W(20241231D) + W(20260101D) + W(20250115D) + W(20231201D) + W(20291212D);
        Obs += W(20240615D) + W(20240301D) + W(20240401D) + W(20250202D) + W(20240110D) + W(20240210D);
        Error('%1', Obs);
    end;

    local procedure W(D: Date): Text
    var
        Row: Record "TPF Row";
        Card: TestPage "TPF Card";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Ok := TryWrite(Card, D);
        Card.Close();
        exit(Format(D, 0, '<Year4><Month,2><Day,2>') + '=' + Format(Ok) + ' ');
    end;

    [TryFunction]
    local procedure TryWrite(var Card: TestPage "TPF Card"; D: Date)
    begin
        Card.Dt.SetValue(D);
    end;

    local procedure IdText(Id: Guid): Text
    begin
        exit(LowerCase(DelChr(Format(Id), '=', '{}')));
    end;
}
