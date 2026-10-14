// The observe-only helper of the probe workflow: a probe test calls Observe / ObserveError for every question and Finish() at the end;
// Finish raises Error('OBSERVE:' + name, value pairs) so the failure message carries the values BC produced. A script then turns each test's
// Finish() into Assert.AreEqual on the observed values.
//   pair separator: U+241E, name/value separator: U+241F (printable, so the failure message stays valid XML)
//   a value is the text as given with CR, LF and TAB written as \r, \n and \t and the two separators as ?
//   ObserveError(Name) records GetLastErrorText() as Name|text and GetLastErrorCode() as Name|code, then clears the last error.
// A failure message keeps about 2000 characters: Finish() raises at most 1800 characters of pairs, ends a cut message with the marker
// <MORE> and keeps the rest in the Observer variable of the test codeunit; a test named <Test>_More1, _More2 ... that calls More() raises the next
// piece (the tests of a codeunit run in one session, in declaration order). Not a test codeunit.
codeunit 69160 "Probe Observer"
{
    var
        Pairs: Text;
        Expected: Text;
        Remaining: Text;

    procedure Observe(ObservedName: Text; ObservedValue: Text)
    var
        Rs: Text[1];
        Us: Text[1];
        Cr: Text[1];
        Lf: Text[1];
        Tab: Text[1];
        Escaped: Text;
    begin
        Rs[1] := 9246;
        Us[1] := 9247;
        Cr[1] := 13;
        Lf[1] := 10;
        Tab[1] := 9;
        Escaped := Scrub(ObservedValue).Replace(Rs, '?').Replace(Us, '?').Replace(Cr, '\r').Replace(Lf, '\n').Replace(Tab, '\t');
        Pairs += ObservedName + Us + Escaped + Rs;
    end;

    // Replaces what changes from run to run (the app version, the run time, the company id, the runner) by a fixed placeholder, so an
    // observed text can be asserted: <ExtensionVersion>, <DateAndTime>, <CompanyId>, <Year>, <MonthNumber>, <DayNumber>, <Hour>, <Minute>,
    // <UserName>, <TenantEntraId>, <EnvironmentName>, <EnvironmentType>, <CompanyName> and <CompanyDisplayName> elements of a report dataset header, and the app version at the end of a call stack frame.
    local procedure Scrub(Value: Text): Text
    begin
        Value := ReplaceBetween(Value, '<ExtensionVersion>', '</ExtensionVersion>', 'x');
        Value := ReplaceBetween(Value, '<DateAndTime>', '</DateAndTime>', 'x');
        Value := ReplaceBetween(Value, '<CompanyId>', '</CompanyId>', 'x');
        Value := ReplaceBetween(Value, '<Year>', '</Year>', 'x');
        Value := ReplaceBetween(Value, '<MonthNumber>', '</MonthNumber>', 'x');
        Value := ReplaceBetween(Value, '<DayNumber>', '</DayNumber>', 'x');
        Value := ReplaceBetween(Value, '<Hour>', '</Hour>', 'x');
        Value := ReplaceBetween(Value, '<Minute>', '</Minute>', 'x');
        Value := ReplaceBetween(Value, '<UserName>', '</UserName>', 'x');
        Value := ReplaceBetween(Value, '<TenantEntraId>', '</TenantEntraId>', 'x');
        Value := ReplaceBetween(Value, '<EnvironmentName>', '</EnvironmentName>', 'x');
        Value := ReplaceBetween(Value, '<EnvironmentType>', '</EnvironmentType>', 'x');
        Value := ReplaceBetween(Value, '<CompanyName>', '</CompanyName>', 'x');
        Value := ReplaceBetween(Value, '<CompanyDisplayName>', '</CompanyDisplayName>', 'x');
        Value := ReplaceBetween(Value, 'AL Language Coverage Tests by AL Language version ', '\', 'x');
        exit(Value);
    end;

    // Every occurrence of Start ... End becomes Start + With + End (End = '\' also matches the end of the text).
    local procedure ReplaceBetween(Value: Text; StartTag: Text; EndTag: Text; Replacement: Text): Text
    var
        Result: Text;
        Rest: Text;
        StartAt: Integer;
        EndAt: Integer;
    begin
        Rest := Value;
        while true do begin
            StartAt := Rest.IndexOf(StartTag);
            if StartAt = 0 then
                break;
            Result += Rest.Substring(1, StartAt + StrLen(StartTag) - 1);
            Rest := Rest.Substring(StartAt + StrLen(StartTag));
            EndAt := Rest.IndexOf(EndTag);
            if EndAt = 0 then begin
                Result += Replacement;
                Rest := '';
                break;
            end;
            Result += Replacement;
            Rest := Rest.Substring(EndAt);
        end;
        exit(Result + Rest);
    end;

    procedure ObserveError(ObservedName: Text)
    begin
        Observe(ObservedName + '|text', GetLastErrorText());
        Observe(ObservedName + '|code', GetLastErrorCode());
        ClearLastError();
    end;

    // The final form of an observed test: the script that turns Finish() into Expect(...) calls and Verify() writes the values BC produced.
    procedure Expect(ExpectedName: Text; ExpectedValue: Text)
    var
        Rs: Text[1];
        Us: Text[1];
    begin
        Rs[1] := 9246;
        Us[1] := 9247;
        Expected += ExpectedName + Us + ExpectedValue + Rs;
    end;

    procedure Verify()
    var
        Rs: Text[1];
        Us: Text[1];
        Got: Text;
        Want: Text;
        GotPair: Text;
        WantPair: Text;
        GotList: List of [Text];
        WantList: List of [Text];
        Index: Integer;
    begin
        Rs[1] := 9246;
        Us[1] := 9247;
        Got := Pairs;
        Want := Expected;
        Pairs := '';
        Expected := '';
        if Got = Want then
            exit;
        GotList := Got.Split(Rs);
        WantList := Want.Split(Rs);
        for Index := 1 to WantList.Count() do begin
            WantPair := WantList.Get(Index);
            if Index > GotList.Count() then
                Error('observation %1 missing: expected [%2]', Index, WantPair.Replace(Us, ' = '));
            GotPair := GotList.Get(Index);
            if GotPair <> WantPair then
                Error('observation %1: expected [%2] but was [%3]', Index, WantPair.Replace(Us, ' = '), GotPair.Replace(Us, ' = '));
        end;
        Error('%1 more observation(s) than expected, the first [%2]', GotList.Count() - WantList.Count(), GotList.Get(WantList.Count() + 1).Replace(Us, ' = '));
    end;

    // For a test whose values depend on the tier (they are recorded, not asserted).
    procedure Discard()
    begin
        Pairs := '';
        Expected := '';
    end;

    procedure Finish()
    var
        State: Codeunit "Probe Observer State";
    begin
        Remaining := Pairs;
        Pairs := '';
        State.Raise('OBSERVE', Remaining);
    end;

    procedure More()
    var
        State: Codeunit "Probe Observer State";
    begin
        State.Raise('OBSERVEMORE', Remaining);
    end;
}

// Plain helper (not SingleInstance: the rest of a long observation lives in the Observer variable of the test codeunit, so no state is shared
// between test codeunits).
codeunit 69163 "Probe Observer State"
{
    procedure Raise(Prefix: Text; var Rest: Text)
    var
        Piece: Text;
    begin
        Piece := CopyStr(Rest, 1, 1800);
        Rest := CopyStr(Rest, 1801);
        if Rest <> '' then
            Error('%1:%2<MORE>', Prefix, Piece);
        Error('%1:%2', Prefix, Piece);
    end;
}

// Kept from an earlier version of Finish() that stored the text here (a test run rolls the rows back, so it never worked); removing it
// would be a destructive schema change for databases that have the earlier app version.
table 69162 "Probe Observer Entry"
{
    DataClassification = SystemMetadata;
    ObsoleteState = Pending;
    ObsoleteReason = 'Not used.';
    ObsoleteTag = '1.0';

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Content; Blob) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
