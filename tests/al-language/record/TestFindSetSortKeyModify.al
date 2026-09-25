// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-next-method
// Scope: in-scope
// Fixtures used: Assert (60021), and the table below
//
// The subject: a FindSet()/Next() loop sorted on a secondary key, where the loop body
// changes that key field through a SECOND record variable. Which rows does Next() reach?
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4678 (Base Application's
// Gen. Journal Line.RenumberDocumentNo writes "Document No." through a second variable).
//
// What BC does: a write to the table invalidates every other open result set on it, and the
// next Next() re-reads from the loop variable's current key values, strictly after them. So a
// row renamed to sort after the cursor is reached again, and a value written after FindSet is
// the value the loop reads. The loops below stop at 11 visits; without the cap the "rename
// past the cursor" shape does not terminate.

table 60398 "FSK Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Doc; Code[20]) { }
        field(3; Payload; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByDoc; Doc) { }
    }
}

codeunit 60367 "FSK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed(Prefix: Text)
    var
        Row: Record "FSK Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 3 do begin
            Row.Init();
            Row.Id := i;
            Row.Doc := CopyStr(Prefix + Format(i), 1, 20);
            Row.Insert();
        end;
    end;

    // Mode 1: move the visited row AFTER every unvisited row, through a second variable.
    // Mode 2: move the visited row BEFORE every unvisited row, through a second variable.
    // Mode 3: move the visited row AFTER every unvisited row, through the loop variable itself.
    local procedure Walk(Mode: Integer; ForUpdate: Boolean; var Visits: Integer): Text
    var
        Row: Record "FSK Row";
        Row2: Record "FSK Row";
        Trace: Text;
    begin
        Visits := 0;
        Row.SetCurrentKey(Doc);
        if Row.FindSet(ForUpdate) then
            repeat
                Visits += 1;
                Trace += Format(Row.Id) + ':' + Row.Doc + ' ';
                case Mode of
                    1, 2:
                        begin
                            Row2.Get(Row.Id);
                            if Mode = 1 then
                                Row2.Doc := CopyStr('Z' + Format(Visits), 1, 20)
                            else
                                Row2.Doc := CopyStr('A' + Format(Visits), 1, 20);
                            Row2.Modify();
                        end;
                    3:
                        begin
                            Row.Doc := CopyStr('Z' + Format(Visits), 1, 20);
                            Row.Modify();
                        end;
                end;
            until (Row.Next() = 0) or (Visits > 10);
        exit(Trace);
    end;

    [Test]
    procedure SecondVar_KeyMovedPastUnvisitedRows_NextRevisitsRenamedRows()
    // THE ARM from #4678. Each visited row is renamed to sort after every unvisited row.
    // Next() seeks past the loop variable's key (A1, A2, ...), so after A3 it finds the
    // renamed rows Z1, Z2, Z3, renames them again, and keeps going until the cap.
    var
        Visits: Integer;
        Trace: Text;
    begin
        Seed('A');
        Trace := Walk(1, false, Visits);
        Assert.AreEqual('1:A1 2:A2 3:A3 1:Z1 2:Z2 3:Z3 1:Z4 2:Z5 3:Z6 1:Z7 2:Z8 ', Trace, 'visit order');
        Assert.AreEqual(11, Visits, 'rows visited');
    end;

    [Test]
    procedure SecondVar_KeyMovedPastUnvisitedRows_FindSetForUpdate_NextRevisitsRenamedRows()
    // Same as above with FindSet(true): the lock does not change which rows Next() reaches.
    var
        Visits: Integer;
        Trace: Text;
    begin
        Seed('A');
        Trace := Walk(1, true, Visits);
        Assert.AreEqual('1:A1 2:A2 3:A3 1:Z1 2:Z2 3:Z3 1:Z4 2:Z5 3:Z6 1:Z7 2:Z8 ', Trace, 'visit order');
        Assert.AreEqual(11, Visits, 'rows visited');
    end;

    [Test]
    procedure SecondVar_KeyMovedBeforeUnvisitedRows_EveryRowVisitedOnce()
    // The mirror image: each visited row is renamed to sort BEFORE the unvisited rows.
    var
        Visits: Integer;
        Trace: Text;
    begin
        Seed('M');
        Trace := Walk(2, false, Visits);
        Assert.AreEqual('1:M1 2:M2 3:M3 ', Trace, 'visit order');
        Assert.AreEqual(3, Visits, 'rows visited');
    end;

    [Test]
    procedure SecondVar_AfterLoop_EachRowCarriesItsLastVisitsKey()
    // The writes themselves landed: each row holds the value written on its LAST visit
    // (visits 10, 11 and 9 for rows 1, 2 and 3).
    var
        Row: Record "FSK Row";
        Visits: Integer;
    begin
        Seed('A');
        Walk(1, false, Visits);
        Row.Get(1);
        Assert.AreEqual('Z10', Row.Doc, 'row 1');
        Row.Get(2);
        Assert.AreEqual('Z11', Row.Doc, 'row 2');
        Row.Get(3);
        Assert.AreEqual('Z9', Row.Doc, 'row 3');
    end;

    [Test]
    procedure SecondVar_NonKeyFieldOfUnvisitedRowChanged_LoopReadsTheNewValue()
    // When the second variable changes a NON-key field of a row the loop has not reached yet,
    // Next() hands that row back with the new value, not the one FindSet found.
    var
        Row: Record "FSK Row";
        Row2: Record "FSK Row";
        Seen: Integer;
        Visits: Integer;
    begin
        Seed('A');
        Row.SetCurrentKey(Doc);
        if Row.FindSet() then
            repeat
                Visits += 1;
                if Visits = 1 then begin
                    Row2.Get(3);
                    Row2.Payload := 99;
                    Row2.Modify();
                end;
                if Row.Id = 3 then
                    Seen := Row.Payload;
            until (Row.Next() = 0) or (Visits > 10);
        Assert.AreEqual(3, Visits, 'rows visited');
        Assert.AreEqual(99, Seen, 'Payload of row 3 as the loop reached it');
        Row2.Get(3);
        Assert.AreEqual(99, Row2.Payload, 'the write itself landed');
    end;

    [Test]
    procedure SameVar_KeyMovedPastUnvisitedRows_NextContinuesFromTheNewKey()
    // The contrast: modifying the key through the LOOP variable moves that variable, and
    // Next() continues from its new position (Z1), past which there is no row. This is the
    // hazard the second variable in RenumberDocumentNo exists to avoid.
    var
        Visits: Integer;
        Trace: Text;
    begin
        Seed('A');
        Trace := Walk(3, false, Visits);
        Assert.AreEqual('1:A1 ', Trace, 'visit order');
        Assert.AreEqual(1, Visits, 'rows visited');
    end;
}
