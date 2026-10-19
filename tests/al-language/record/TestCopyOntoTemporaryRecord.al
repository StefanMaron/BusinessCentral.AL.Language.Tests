// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-copy-method
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT Page Find Record Row (60671); shared Assert (60021)
// BC versions: 27.0+
//
/// <summary>
/// CLAIM: Copy(FromRecord) onto a TEMPORARY record variable copies the source's filters,
/// current key and sort direction, and leaves the temporary table's own rows in place. The
/// temporary variable stays temporary.
///
/// This is the half of Copy nobody writes down, and a page that serves its rows from a
/// temporary buffer depends on all of it: "TempBuf.Copy(Rec)" inside OnFindRecord is what makes
/// a user's filter and the page's sort apply to a rowset the page produced itself. If Copy
/// replaced the buffer's contents with the source table's, the pattern would return table rows;
/// if it dropped the filters, a filtered page would show every row; if it dropped the
/// direction, a descending page would walk upward.
///
/// WHAT IS PINNED HERE, and what each assertion would catch if it broke:
///
///   1. IsTemporary STAYS TRUE. Copy from a non-temporary source does not turn the variable
///      into a view over the real table.
///   2. THE BUFFER KEEPS ITS OWN ROWS, NARROWED BY THE COPIED FILTERS. Four rows are inserted
///      into the buffer and the source carries two filters; Count answers 3 -- the buffer's own
///      rows minus the one the copied filter excludes. Not 4 (filters dropped) and not the
///      table's count (rows replaced).
///   3. THE FILTERS COME ACROSS, per field, so a wrong one is named rather than hidden in a
///      composite string.
///   4. THE CURRENT KEY COMES ACROSS.
///   5. THE SORT DIRECTION COMES ACROSS. Find('-') answers the buffer's DESCENDING first row.
///      The filter excludes 'L0001', so ascending would answer 'L0003' and descending 'L0007':
///      the two directions are distinguishable, which is what makes this assertion worth
///      making.
/// </summary>
codeunit 60680 "ALT Copy Onto Temporary Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedTableAndBuffer(var TempBuf: Record "ALT Page Find Record Row" temporary)
    var
        Row: Record "ALT Page Find Record Row";
        I: Integer;
    begin
        Row.Reset();
        Row.DeleteAll();
        for I := 1 to 8 do begin
            Row.Init();
            Row."No." := 'L' + PadStr('', 4 - StrLen(Format(I)), '0') + Format(I);
            if I mod 2 = 1 then
                Row.Description := 'Included'
            else
                Row.Description := 'Excluded';
            Row.Insert();
        end;

        TempBuf.Reset();
        TempBuf.DeleteAll();
        Row.Reset();
        Row.SetRange(Description, 'Included');
        if Row.FindSet() then
            repeat
                TempBuf := Row;
                TempBuf.Insert();
            until Row.Next() = 0;
    end;

    [Test]
    procedure CopyOntoTemporary_CarriesFiltersKeyAndDirection_AndKeepsItsOwnRows()
    var
        Src: Record "ALT Page Find Record Row";
        TempBuf: Record "ALT Page Find Record Row" temporary;
    begin
        // [SCENARIO] A buffer holding four rows of its own is copied over from a filtered,
        // descending source. Every property the temporary-buffer page pattern relies on is
        // asserted on the result.
        SeedTableAndBuffer(TempBuf);

        Src.Reset();
        Src.SetCurrentKey("No.");
        Src.Ascending(false);
        Src.SetRange(Description, 'Included');
        Src.SetFilter("No.", '<>%1', 'L0001');

        TempBuf.Copy(Src);

        Assert.IsTrue(TempBuf.IsTemporary, 'the variable is still temporary after Copy');
        Assert.AreEqual(3, TempBuf.Count, 'the buffer''s own four rows, narrowed by the copied filters');
        Assert.AreEqual('<>L0001', TempBuf.GetFilter("No."), 'the "No." filter Copy carried');
        Assert.AreEqual('Included', TempBuf.GetFilter(Description), 'the Description filter Copy carried');
        Assert.AreEqual('No.', TempBuf.CurrentKey, 'the current key Copy carried');

        Assert.IsTrue(TempBuf.Find('-'), 'Find(''-'') over the copied-onto buffer');
        Assert.AreEqual('L0007', TempBuf."No.",
          'the buffer''s DESCENDING first row -- ascending would answer L0003');
    end;

    [Test]
    procedure CopyOntoTemporary_WithoutTheCopy_TheBufferIsUnfilteredAndAscending()
    var
        TempBuf: Record "ALT Page Find Record Row" temporary;
    begin
        // [SCENARIO] The control arm. The same buffer, never copied over, answers all four of
        // its rows in ascending order -- so every assertion in the test above is a statement
        // about what Copy did, not about how the buffer was filled.
        SeedTableAndBuffer(TempBuf);

        Assert.AreEqual(4, TempBuf.Count, 'the buffer''s own rows, unfiltered');
        Assert.AreEqual('', TempBuf.GetFilter("No."), 'no "No." filter before a Copy');
        Assert.IsTrue(TempBuf.Find('-'), 'Find(''-'') over the untouched buffer');
        Assert.AreEqual('L0001', TempBuf."No.", 'the buffer''s ascending first row');
    end;
}
