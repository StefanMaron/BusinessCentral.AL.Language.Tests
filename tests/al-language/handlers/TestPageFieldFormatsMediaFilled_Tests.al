// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPF Media Row (69933), TPF Media Card (69933)
// BC versions: 27.0+

codeunit 69934 "TPF Media Filled Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ValidPngBase64: Label 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAAAAAA6fptVAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=', Locked = true;

    [Test]
    procedure Probe_Value_MediaFilled()
    var
        Row: Record "TPF Media Row";
        Card: TestPage "TPF Media Card";
        TempBlob: Codeunit "Temp Blob";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        OutStr: OutStream;
        Obs: Text;
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
        Obs := 'Pic=[' + Card.Pic.Value() + '] One=[' + Card.One.Value() + ']';
        Card.Close();
        Error('%1', Obs);
    end;
}
