// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: CDC Ref Row (60327), CDC Owner (60328)
//
// `Database::<Object>` is AL's object-reference syntax, and it is legal inside the where()
// clause of a CalcFormula and of a TableRelation:
//
//   CalcFormula   = count("CDC Ref Row" where("Owner No." = field("No."),
//                                             "Table ID"  = const(Database::"CDC Owner")));
//   TableRelation = "CDC Ref Row"."Code" where("Table ID" = const(Database::"CDC Owner"));
//
// The Base Application leans on this constantly -- every "Coupled to Dataverse" FlowField is
// `exist("CRM Integration Record" where("Table ID" = const(Database::<the table>)))` -- but the
// corpus had no test for it in either property, only in a page's SubPageLink.
//
// CLAIM under test: the constant contributes the referenced object's ID to the condition, on
// an Integer column, the same as writing 60328 there by hand. Nothing about the seeded data
// can be answered by carrying the constant's SOURCE TEXT through:
//
//   * "Owner Row Count" (pinned to Database::"CDC Owner") and "Ref Row Count" (pinned to
//     Database::"CDC Ref Row") read 2 and 1 on the same owner, so the two constants must
//     resolve to two DIFFERENT numbers;
//   * every seeded owner also carries rows with a third "Table ID" (0), so a condition that
//     was dropped altogether reads 4 and 5127, not 2 and 120;
//   * a condition that matched nothing reads 0.
//
// The TableRelation half asserts the same constant in the other property, against a control
// field whose relation targets the same table with no where() clause at all -- so a refusal
// cannot be read as "the relation is broken", only as "the where() clause excluded that row".
codeunit 60329 "CDC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        RefRow: Record "CDC Ref Row";
        Owner: Record "CDC Owner";
    begin
        RefRow.Reset();
        RefRow.DeleteAll();
        Owner.Reset();
        Owner.DeleteAll();

        AddOwner('O1');
        AddOwner('O2');

        // O1: two rows carrying THIS table's id (100 + 20 = 120), one carrying the other
        // fixture table's id, one carrying an id belonging to neither.
        AddRefRow('R1', Database::"CDC Owner", 'O1', 100);
        AddRefRow('R2', Database::"CDC Owner", 'O1', 20);
        AddRefRow('R3', Database::"CDC Ref Row", 'O1', 7);
        AddRefRow('R4', 0, 'O1', 5000);

        // O2: nothing carrying "CDC Owner"'s id at all, so the negative direction is a real
        // zero over a non-empty row set rather than an empty table.
        AddRefRow('R5', Database::"CDC Ref Row", 'O2', 3);
        AddRefRow('R6', 0, 'O2', 11);
    end;

    local procedure AddOwner(No: Code[20])
    var
        Owner: Record "CDC Owner";
    begin
        Owner.Init();
        Owner."No." := No;
        Owner.Insert(false);
    end;

    local procedure AddRefRow(RowCode: Code[20]; TableId: Integer; OwnerNo: Code[20]; Amt: Decimal)
    var
        RefRow: Record "CDC Ref Row";
    begin
        RefRow.Init();
        RefRow."Code" := RowCode;
        RefRow."Table ID" := TableId;
        RefRow."Owner No." := OwnerNo;
        RefRow.Amount := Amt;
        RefRow.Insert(false);
    end;

    [Test]
    procedure CalcFields_ConstDatabaseTable_CountsOnlyRowsCarryingThatTableId()
    // CLAIM: const(Database::"CDC Owner") narrows the source rows to those whose Integer
    // "Table ID" holds 60328 -- 2 of O1's 4 rows, summing to 120, not all 4 summing to 5127.
    var
        Owner: Record "CDC Owner";
    begin
        Initialize();

        Owner.Get('O1');
        Owner.CalcFields("Owns Owner Rows", "Owner Row Count", "Ref Row Count", "Owner Row Amount");

        Assert.IsTrue(Owner."Owns Owner Rows",
            'exist() narrowed by const(Database::"CDC Owner") must see O1''s two rows carrying that table id');
        Assert.AreEqual(2, Owner."Owner Row Count",
            'count() narrowed by const(Database::"CDC Owner") must count exactly the 2 rows carrying 60328');
        Assert.AreEqual(120, Owner."Owner Row Amount",
            'sum() narrowed by const(Database::"CDC Owner") must add only the 2 rows carrying 60328');

        // The same shape pinned to the OTHER table's id, on the same owner and the same rows.
        Assert.AreEqual(1, Owner."Ref Row Count",
            'count() narrowed by const(Database::"CDC Ref Row") must count the single row carrying 60327');
    end;

    [Test]
    procedure CalcFields_ConstDatabaseTable_ReadsZeroWhenNoRowCarriesThatTableId()
    // CLAIM: the negative direction. O2 has rows, and none of them carries "CDC Owner"'s id,
    // so the constant excludes all of them -- while the sibling FlowField pinned to the other
    // constant still finds its row, proving the rows are there to be counted.
    var
        Owner: Record "CDC Owner";
    begin
        Initialize();

        Owner.Get('O2');
        Owner.CalcFields("Owns Owner Rows", "Owner Row Count", "Ref Row Count", "Owner Row Amount");

        Assert.IsFalse(Owner."Owns Owner Rows",
            'exist() must be false for an owner with no row carrying const(Database::"CDC Owner")''s id');
        Assert.AreEqual(0, Owner."Owner Row Count",
            'count() must be 0 for an owner with no row carrying const(Database::"CDC Owner")''s id');
        Assert.AreEqual(0, Owner."Owner Row Amount",
            'sum() must be 0 for an owner with no row carrying const(Database::"CDC Owner")''s id');
        Assert.AreEqual(1, Owner."Ref Row Count",
            'the sibling FlowField pinned to const(Database::"CDC Ref Row") must still find O2''s row');
    end;

    [Test]
    procedure CalcFields_ConstDatabaseTable_MatchesWhatTheSameIdSelectsAsAFilter()
    // CLAIM: the constant IS the object id and nothing else -- the FlowField selects exactly
    // the rows a hand-written SetRange over the same two ids selects, and the two ids are the
    // two distinct table numbers 60328 and 60327.
    var
        Owner: Record "CDC Owner";
        RefRow: Record "CDC Ref Row";
    begin
        Initialize();

        Assert.AreEqual(60328, Database::"CDC Owner", 'Database::"CDC Owner" is that table''s object id');
        Assert.AreEqual(60327, Database::"CDC Ref Row", 'Database::"CDC Ref Row" is that table''s object id');

        Owner.Get('O1');
        Owner.CalcFields("Owner Row Count", "Ref Row Count");

        RefRow.SetRange("Owner No.", 'O1');
        RefRow.SetRange("Table ID", Database::"CDC Owner");
        Assert.AreEqual(RefRow.Count(), Owner."Owner Row Count",
            'the const(Database::"CDC Owner") FlowField must count what SetRange("Table ID", 60328) counts');
        Assert.AreEqual(2, RefRow.Count(), 'two of O1''s rows carry 60328');

        RefRow.SetRange("Table ID", Database::"CDC Ref Row");
        Assert.AreEqual(RefRow.Count(), Owner."Ref Row Count",
            'the const(Database::"CDC Ref Row") FlowField must count what SetRange("Table ID", 60327) counts');
        Assert.AreEqual(1, RefRow.Count(), 'one of O1''s rows carries 60327');
    end;

    [Test]
    procedure Validate_RelationWhereConstDatabaseTable_AcceptsARowCarryingThatTableId()
    // CLAIM: the same constant in a TableRelation where() clause admits the rows whose
    // "Table ID" holds that object id.
    var
        Owner: Record "CDC Owner";
    begin
        Initialize();

        Owner.Get('O1');
        Owner.Validate("Pinned Ref", 'R1');

        Assert.AreEqual('R1', Owner."Pinned Ref",
            'a "CDC Ref Row" carrying const(Database::"CDC Owner")''s id must satisfy the relation');
    end;

    [Test]
    procedure Validate_RelationWhereConstDatabaseTable_RefusesARowCarryingAnotherTableId()
    // CLAIM: and it refuses the rows whose "Table ID" holds anything else. R3 exists and is a
    // perfectly good "Code" -- the control field, whose relation has no where() clause, takes
    // it -- so the refusal can only come from the const(Database::...) condition.
    var
        Owner: Record "CDC Owner";
    begin
        Initialize();

        Owner.Get('O1');

        Owner.Validate("Plain Ref", 'R3');
        Assert.AreEqual('R3', Owner."Plain Ref",
            'the control relation, with no where() clause, must accept R3');

        asserterror Owner.Validate("Pinned Ref", 'R3');
        Assert.ExpectedError('cannot be found in the related table');
    end;
}
