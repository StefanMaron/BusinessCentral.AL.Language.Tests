// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-next-method
// Scope: in-scope
// Fixtures used: Assert (60021), and the table below
//
// The subject is WHERE Next() CONTINUES FROM after a Get() has moved the record, while a
// FindSet() result set is open. Those are two different positions, and nothing upstream
// measures which one BC uses.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4161, which measures the
// runner answering from the FindSet enumerator and reasons from BC's own IL that BC answers
// from the Get'd record -- and says plainly that it has NOT run this against a service tier.
// These arms are what turn that into a verdict. Nothing here predicts the runner's answer.
//
// THE DISCRIMINATION IS THE POINT. With rows 1..5 and FindSet() then Get(4):
//
//   continuing from the FindSet enumerator  -> Next() lands on 2
//   continuing from the Get'd record        -> Next() lands on 5
//
// Two different integers, so one arm settles it either way and neither outcome needs
// interpretation. The companion arms below rule out the cheap alternative explanations --
// that Next() is broken generally, or that Get() did not move the record at all.

table 60986 "FGN Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Payload; Text[20]) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

codeunit 60979 "FGN Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Seed()
    var
        Row: Record "FGN Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to 5 do begin
            Row.Init();
            Row."No." := i;
            Row.Payload := 'row' + Format(i);
            Row.Insert();
        end;
    end;

    [Test]
    procedure Next_AfterFindSetThenGet_ContinuesFromTheGotRecord()
    // THE ARM. FindSet() opens a result set positioned on row 1; Get(4) then loads row 4.
    // Whichever position Next() continues from decides the answer, and the two candidates
    // are distinguishable integers rather than a pass/fail.
    var
        Row: Record "FGN Row";
        Moved: Integer;
    begin
        Seed();

        Row.FindSet();
        Assert.AreEqual(1, Row."No.", 'FindSet must position on the first row, or the rest of this test means nothing');

        Row.Get(4);
        Assert.AreEqual(4, Row."No.", 'Get(4) must load row 4 before Next() is asked anything');

        Moved := Row.Next();
        Assert.AreEqual(1, Moved, 'Next() must report that it moved; a 0 here means it ran off the end and the No. below is stale');
        Assert.AreEqual(
            5, Row."No.",
            'Next() after FindSet() then Get(4) must continue from the record Get loaded (5), not from the FindSet result set (2)');
    end;

    [Test]
    procedure Next_AfterFindSetAlone_WalksTheResultSet()
    // Control: without a Get() in between, Next() walks the FindSet result set normally.
    // If this failed, the arm above would be measuring a broken Next() rather than the
    // position question.
    var
        Row: Record "FGN Row";
    begin
        Seed();

        Row.FindSet();
        Assert.AreEqual(1, Row."No.", 'FindSet must position on the first row');
        Assert.AreEqual(1, Row.Next(), 'Next() must report that it moved');
        Assert.AreEqual(2, Row."No.", 'Next() with no intervening Get must walk the result set to row 2');
    end;

    [Test]
    procedure Next_AfterGetWithNoFindSet_ContinuesFromTheGotRecord()
    // Control: with no result set open at all, Next() plainly continues from the Get'd
    // record. This is what pins the claim to the INTERACTION -- if this and the arm above
    // disagree, an open FindSet result set is what changes the answer, which is exactly the
    // mechanism #4161 is about.
    var
        Row: Record "FGN Row";
    begin
        Seed();

        Row.Get(4);
        Assert.AreEqual(4, Row."No.", 'Get(4) must load row 4');
        Assert.AreEqual(1, Row.Next(), 'Next() must report that it moved');
        Assert.AreEqual(5, Row."No.", 'Next() after a bare Get(4) must continue from row 4 to row 5');
    end;

    [Test]
    procedure Next_AfterFindSetThenGetLastRow_ReportsNoFurtherRow()
    // The negative direction. Get(5) is the last row, so continuing from the Get'd record
    // must run off the end and answer 0. Continuing from the FindSet enumerator would
    // instead find row 2 and answer 1 -- so this arm discriminates the same two candidates
    // through a different observable than the No. above.
    var
        Row: Record "FGN Row";
    begin
        Seed();

        Row.FindSet();
        Row.Get(5);
        Assert.AreEqual(5, Row."No.", 'Get(5) must load the last row');
        Assert.AreEqual(
            0, Row.Next(),
            'Next() past the last row must answer 0; a 1 here means it continued from the FindSet result set instead');
    end;
}
