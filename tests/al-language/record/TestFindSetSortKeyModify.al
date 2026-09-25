// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-next-method
// Scope: in-scope
// Fixtures used: Assert (60021), and the table below
//
// The subject: a FindSet()/Next() loop sorted on a secondary key, where the loop body
// changes that key field on the current row. Which rows does Next() still reach?
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4678. Base Application's
// Gen. Journal Line.RenumberDocumentNo loops on a key that includes "Document No." and
// writes the new "Document No." through a SECOND record variable (Get + Modify). Microsoft's
// own tests (codeunit 134920 "ERM General Journal UT") expect every line to be visited once.
//
// Three rows only: a SQL-backed FindSet reads in batches, and a small set keeps every arm
// inside the first one, so the answer does not depend on a batch size.

table 60999 "FSK Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Doc; Code[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
        key(ByDoc; Doc) { }
    }
}

codeunit 60919 "FSK Tests"
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
    procedure SecondVar_KeyMovedPastUnvisitedRows_EveryRowVisitedOnce()
    // THE ARM from #4678. Each visited row is renamed to sort after every unvisited row.
    // The loop variable itself is never modified, so Next() must walk the three rows it
    // started with, in their original order, exactly once each.
    var
        Visits: Integer;
        Trace: Text;
    begin
        Seed('A');
        Trace := Walk(1, false, Visits);
        Assert.AreEqual('1:A1 2:A2 3:A3 ', Trace, 'visit order');
        Assert.AreEqual(3, Visits, 'rows visited');
    end;

    [Test]
    procedure SecondVar_KeyMovedPastUnvisitedRows_FindSetForUpdate_EveryRowVisitedOnce()
    // Same as above with FindSet(true): the lock does not change which rows Next() reaches.
    var
        Visits: Integer;
        Trace: Text;
    begin
        Seed('A');
        Trace := Walk(1, true, Visits);
        Assert.AreEqual('1:A1 2:A2 3:A3 ', Trace, 'visit order');
        Assert.AreEqual(3, Visits, 'rows visited');
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
    procedure SecondVar_AfterLoop_EveryRowCarriesItsNewKey()
    // The writes themselves landed: after the loop each row holds the value written on
    // its own visit, so the visit order above is also the renumbering order.
    var
        Row: Record "FSK Row";
        Visits: Integer;
    begin
        Seed('A');
        Walk(1, false, Visits);
        Row.Get(1);
        Assert.AreEqual('Z1', Row.Doc, 'row 1');
        Row.Get(2);
        Assert.AreEqual('Z2', Row.Doc, 'row 2');
        Row.Get(3);
        Assert.AreEqual('Z3', Row.Doc, 'row 3');
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
