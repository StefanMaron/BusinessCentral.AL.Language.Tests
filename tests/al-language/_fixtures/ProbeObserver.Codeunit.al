// The observe-only helper of the probe workflow: a probe test calls Observe / ObserveError for every question and Finish() at the end;
// Finish raises Error('OBSERVE:' + name, value pairs) so the failure message carries the values BC produced. A script then turns each test's
// Finish() into Assert.AreEqual on the observed values.
//   pair separator: U+241E, name/value separator: U+241F (printable, so the failure message stays valid XML)
//   a value is the text as given with CR, LF and TAB written as \r, \n and \t and the two separators as ?
//   ObserveError(Name) records GetLastErrorText() as Name|text and GetLastErrorCode() as Name|code, then clears the last error.
// A failure message keeps about 2000 characters, so Finish() also stores the whole text in the table "Probe Observer Entry" (committed) and
// starts the message with OBSERVE#<entry no>:. When a message is cut, a helper outside the repo reads the table to get the rest.
// Fixtures used: table "Probe Observer Entry". Not a test codeunit.
codeunit 69160 "Probe Observer"
{
    var
        Pairs: Text;

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
        Escaped := ObservedValue.Replace(Rs, '?').Replace(Us, '?').Replace(Cr, '\r').Replace(Lf, '\n').Replace(Tab, '\t');
        Pairs += ObservedName + Us + Escaped + Rs;
    end;

    procedure ObserveError(ObservedName: Text)
    begin
        Observe(ObservedName + '|text', GetLastErrorText());
        Observe(ObservedName + '|code', GetLastErrorCode());
        ClearLastError();
    end;

    procedure Finish()
    var
        Entry: Record "Probe Observer Entry";
        OutStr: OutStream;
        Result: Text;
    begin
        Result := Pairs;
        Pairs := '';
        Entry.Init();
        Entry.Content.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(Result);
        Entry.Insert();
        Commit();
        Error('OBSERVE#%1:%2', Entry."Entry No.", Result);
    end;
}

table 69162 "Probe Observer Entry"
{
    DataClassification = SystemMetadata;

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
