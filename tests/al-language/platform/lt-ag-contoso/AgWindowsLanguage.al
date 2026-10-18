// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: every row of the system table Windows Language (2000000045) on a fresh tenant, in key order: the row count, a digest over id, name,
// abbreviated name, code page and tag of all rows, and the writes (Insert, Modify, Delete, DeleteAll) that the table refuses.
// Facts: the full list behind the three or four rows other files pin (record/TestWindowsLanguageTable.al, errors/lt-ms-refusals-129, -133, -137).
// BC versions: 27-29

codeunit 78400 "LT AG Win Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Hash(Value: Text; var State: BigInteger)
    var
        Ch: Char;
        I: Integer;
        Code: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            Ch := Value[I];
            Code := Ch;
            State := (State * 31 + Code) mod 2147483629;
        end;
    end;

    local procedure RowText(var WindowsLanguage: Record "Windows Language"): Text
    begin
        exit(Format(WindowsLanguage."Language ID") + '|' + WindowsLanguage.Name + '|' + WindowsLanguage."Abbreviated Name" + '|' + WindowsLanguage."Primary CodePage" + '|' + WindowsLanguage."Language Tag");
    end;

    [Test]
    procedure WindowsLanguage_AllRows_CountAndDigest()
    var
        WindowsLanguage: Record "Windows Language";
        Dump: Text;
        IdDigest: BigInteger;
        RowDigest: BigInteger;
        Index: Integer;
    begin
        Observer.Observe('count', Format(WindowsLanguage.Count()));
        if WindowsLanguage.FindSet() then
            repeat
                Index += 1;
                Hash(Format(WindowsLanguage."Language ID") + ',', IdDigest);
                Hash(RowText(WindowsLanguage) + ';', RowDigest);
                Dump += RowText(WindowsLanguage) + ';';
            until WindowsLanguage.Next() = 0;
        Observer.Observe('iterated', Format(Index));
        Observer.Observe('id_digest', Format(IdDigest));
        Observer.Observe('row_digest', Format(RowDigest));
        Observer.Observe('dump', Dump);
        Observer.Finish();
    end;


    [Test]
    procedure WindowsLanguage_AllRows_CountAndDigest_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure WindowsLanguage_AllRows_CountAndDigest_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure WindowsLanguage_AllRows_CountAndDigest_More3()
    begin
        Observer.More();
    end;

    [Test]
    procedure WindowsLanguage_AllRows_CountAndDigest_More4()
    begin
        Observer.More();
    end;
}
