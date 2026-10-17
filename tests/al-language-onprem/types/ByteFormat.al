// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/byte/byte-data-type
// Scope: in-scope, OnPrem app (the Byte data type only compiles in a Target = OnPrem app)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app
// Probe: Format of a Byte at and above 0x80 (0x80, 0x9F, 0xA0, 0xBB, 0xBF, 0xEF, 0xFF and 0x7F for comparison), the text length, the code point of the
// character (Text[1] element read as Integer), and the same bytes assigned to a Text[1] and to a Text. The bytes EF BB BF are the UTF-8 byte order mark.
// Object id 61235.

codeunit 61235 "LT Byte Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(Observer: Codeunit "Probe Observer"; Name: Text; Value: Integer)
    var
        B: Byte;
        One: Text[1];
        Shown: Text;
        Code: Integer;
    begin
        B := Value;
        Shown := Format(B);
        One[1] := B;
        Observer.Observe(Name + '_format_len', Format(StrLen(Shown)));
        if StrLen(Shown) > 0 then begin
            Code := Shown[1];
            Observer.Observe(Name + '_format_code1', Format(Code));
        end;
        Code := One[1];
        Observer.Observe(Name + '_text1_code', Format(Code));
        Observer.Observe(Name + '_as_integer', Format(B + 0));
    end;

    [Test]
    procedure Format_Bytes_AroundTheAsciiBoundary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'b7F', 127);
        Show(Observer, 'b80', 128);
        Show(Observer, 'b9F', 159);
        Show(Observer, 'bA0', 160);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Bytes_ByteOrderMark()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'bEF', 239);
        Show(Observer, 'bBB', 187);
        Show(Observer, 'bBF', 191);
        Show(Observer, 'bFF', 255);
        Observer.Finish();
    end;

    [Test]
    procedure TextFromBytes_ByteOrderMark()
    var
        Observer: Codeunit "Probe Observer";
        B1: Byte;
        B2: Byte;
        B3: Byte;
        Bom: Text;
        Index: Integer;
        Code: Integer;
    begin
        B1 := 239;
        B2 := 187;
        B3 := 191;
        Bom := Format(B1) + Format(B2) + Format(B3);
        Observer.Observe('bom_len', Format(StrLen(Bom)));
        for Index := 1 to StrLen(Bom) do begin
            Code := Bom[Index];
            Observer.Observe('bom_code_' + Format(Index), Format(Code));
        end;
        Observer.Finish();
    end;
}
