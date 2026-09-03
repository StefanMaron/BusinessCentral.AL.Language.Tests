// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-enums
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Status (60009), EBF Option Row (60301)
//
// CLAIM: BC resolves the text of an option/enum filter by matching member names with
// both sides trimmed and case ignored, skipping members whose name is zero length,
// and only then falling back to parsing the text as an ordinal. Separately, a member
// declared with AL's quoted-identifier form (a name containing a space, e.g.
// `"Work Center"`) validates, assigns and Formats as the plain unquoted text AL
// declared -- the quoting is source syntax, not part of the member's name.
//
// The practical consequence is AL's blank enum member. AL spells it `value(0; " ")` --
// a single space -- so the empty string matches it after the trim. Base Application
// codeunit 5055 "CustVendBank-Update" depends on exactly that:
//
//     ContBusRel.SetFilter("Link to Table", '<>''''');
//
// Every one of these assertions is about plain BC behaviour, so a service tier, not a
// consumer of this corpus, is what settles it.
codeunit 60300 "EBF Blank Option Filter Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        OptionRow: Record "EBF Option Row";
    begin
        OptionRow.DeleteAll(false);
        Cleanup.Initialize();
    end;

    local procedure SeedStatusRows()
    var
        Rec: Record "ALT Universal";
    begin
        Rec.Init();
        Rec."Entry No." := 1;
        Rec."Status Field" := "ALT Status"::" ";
        Rec.Insert(false);

        Rec.Init();
        Rec."Entry No." := 2;
        Rec."Status Field" := "ALT Status"::Draft;
        Rec.Insert(false);

        Rec.Init();
        Rec."Entry No." := 3;
        Rec."Status Field" := "ALT Status"::Active;
        Rec.Insert(false);
    end;

    [Test]
    procedure EnumFilter_NotEmptyStringLiteral_ExcludesTheBlankMember()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] The Base App shape: '<>''''' -- a filter whose value is a quoted
        //            empty string, negated. It must exclude the blank member and keep
        //            every other one.
        Initialize();
        SeedStatusRows();

        Rec.SetFilter("Status Field", '<>''''');

        Assert.AreEqual(2, Rec.Count(), '<>'''''' must keep exactly the two non-blank rows');
        Rec.FindSet();
        Assert.AreEqual(2, Rec."Entry No.", 'the first surviving row must be the Draft row');
        Rec.Next();
        Assert.AreEqual(3, Rec."Entry No.", 'the second surviving row must be the Active row');
    end;

    [Test]
    procedure EnumFilter_EmptyStringLiteral_MatchesTheBlankMember()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] The un-negated half of the same claim: '''''' selects the blank
        //            member and nothing else. A matcher that simply failed to resolve
        //            the empty string could not pass this and the previous test at once.
        Initialize();
        SeedStatusRows();

        Rec.SetFilter("Status Field", '''''');

        Assert.AreEqual(1, Rec.Count(), ''''''' must select exactly the blank-member row');
        Rec.FindFirst();
        Assert.AreEqual(1, Rec."Entry No.", 'the selected row must be the one whose Status Field is the blank member');
        Assert.AreEqual(0, Rec."Status Field".AsInteger(), 'the selected row must carry ordinal 0');
    end;

    [Test]
    procedure EnumFilter_MemberNameInLowercase_MatchesCaseInsensitively()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] Member names are matched without regard to case.
        Initialize();
        SeedStatusRows();

        Rec.SetFilter("Status Field", 'draft');

        Assert.AreEqual(1, Rec.Count(), 'a lowercase member name must match the Draft member');
        Rec.FindFirst();
        Assert.AreEqual(2, Rec."Entry No.", 'the matched row must be the Draft row');
    end;

    [Test]
    procedure EnumFilter_MemberNameWithSurroundingSpaces_IsTrimmed()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] The member name is quoted, so the spaces survive the filter
        //            tokenizer and reach the option matcher, which trims both sides.
        Initialize();
        SeedStatusRows();

        Rec.SetFilter("Status Field", ''' Draft ''');

        Assert.AreEqual(1, Rec.Count(), 'a quoted member name padded with spaces must still match Draft');
        Rec.FindFirst();
        Assert.AreEqual(2, Rec."Entry No.", 'the matched row must be the Draft row');
    end;

    [Test]
    procedure EnumFilter_TextThatIsNeitherMemberNorOrdinal_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] The matcher is a real matcher: text that names no member and does
        //            not parse as an ordinal is rejected, rather than silently landing
        //            on ordinal 0.
        Initialize();
        SeedStatusRows();

        asserterror Rec.SetFilter("Status Field", 'Purple');
        Assert.ExpectedError('is not an option');
    end;

    [Test]
    procedure EnumFilter_NumericText_FallsBackToTheOrdinal()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] Text that names no member but parses as an integer selects that
        //            ordinal -- the fallback that sits behind the name match.
        Initialize();
        SeedStatusRows();

        Rec.SetFilter("Status Field", '2');

        Assert.AreEqual(1, Rec.Count(), 'the ordinal 2 must select exactly the Active row');
        Rec.FindFirst();
        Assert.AreEqual(3, Rec."Entry No.", 'ordinal 2 is Active, which is Entry No. 3');
    end;

    [Test]
    procedure OptionFilter_SpaceNamedBlankMember_IsMatchedByTheEmptyString()
    var
        OptionRow: Record "EBF Option Row";
    begin
        // [SCENARIO] The same rule on a plain Option field whose ordinal-0 member is
        //            named with a single space.
        Initialize();

        OptionRow.Init();
        OptionRow."Entry No." := 1;
        OptionRow."Space Blank" := OptionRow."Space Blank"::" ";
        OptionRow.Insert(false);

        OptionRow.Init();
        OptionRow."Entry No." := 2;
        OptionRow."Space Blank" := OptionRow."Space Blank"::Draft;
        OptionRow.Insert(false);

        OptionRow.SetFilter("Space Blank", '''''');

        Assert.AreEqual(1, OptionRow.Count(), 'the empty string must match the space-named ordinal-0 member');
        OptionRow.FindFirst();
        Assert.AreEqual(1, OptionRow."Entry No.", 'the matched row must be the one carrying the blank member');
    end;

    [Test]
    procedure OptionFilter_ZeroLengthNamedMember_IsNotMatchedByTheEmptyString()
    var
        OptionRow: Record "EBF Option Row";
    begin
        // [SCENARIO] The distinguishing case. "Empty Blank" names its ordinal-0 member
        //            with nothing at all, and BC's matcher skips zero-length names --
        //            so the empty string resolves to no member here, unlike on the
        //            space-named field above, and the filter is rejected.
        Initialize();

        OptionRow.Init();
        OptionRow."Entry No." := 1;
        OptionRow."Empty Blank" := OptionRow."Empty Blank"::Draft;
        OptionRow.Insert(false);

        asserterror OptionRow.SetFilter("Empty Blank", '''''');
        Assert.ExpectedError('is not an option');
    end;

    [Test]
    procedure OptionValidate_QuotedMultiwordMember_Succeeds()
    var
        OptionRow: Record "EBF Option Row";
    begin
        // [SCENARIO] A member declared with AL's quoted-identifier form (a name with a
        //            space in it) validates and inserts like any other member.
        Initialize();

        OptionRow.Init();
        OptionRow."Entry No." := 1;
        OptionRow.Validate("Quoted Multiword", OptionRow."Quoted Multiword"::"Work Center");
        OptionRow.Insert(false);

        Assert.AreEqual(OptionRow."Quoted Multiword"::"Work Center", OptionRow."Quoted Multiword", 'Validate must set ordinal 1 for "Work Center"');
    end;

    [Test]
    procedure OptionAssign_QuotedMultiwordMember_Succeeds()
    var
        OptionRow: Record "EBF Option Row";
    begin
        // [SCENARIO] Plain assignment (no Validate) of the same quoted member.
        Initialize();

        OptionRow.Init();
        OptionRow."Entry No." := 1;
        OptionRow."Quoted Multiword" := OptionRow."Quoted Multiword"::"Machine Center";
        OptionRow.Insert(false);

        Assert.AreEqual(OptionRow."Quoted Multiword"::"Machine Center", OptionRow."Quoted Multiword", 'assignment must set ordinal 2 for "Machine Center"');
    end;

    [Test]
    procedure OptionFormat_QuotedMultiwordMember_HasNoQuotes()
    var
        OptionRow: Record "EBF Option Row";
    begin
        // [SCENARIO] Format() of a quoted-identifier member returns the plain text AL
        //            declared, not the quoting used to spell the identifier.
        Initialize();

        OptionRow."Quoted Multiword" := OptionRow."Quoted Multiword"::"Work Center";

        Assert.AreEqual('Work Center', Format(OptionRow."Quoted Multiword"), 'Format must strip the identifier quoting');
    end;

    [Test]
    procedure OptionValidate_OnValidateTriggerSeesUnquotedFormat()
    var
        OptionRow: Record "EBF Option Row";
    begin
        // [SCENARIO] The OnValidate trigger on the option field itself calls Format() on
        //            the just-validated value and clears a third field -- the shape a
        //            real AL project uses (an option field driving a derived name field).
        //            The trigger must see the unquoted member name, and the cleared field
        //            must actually be cleared.
        Initialize();

        OptionRow.Init();
        OptionRow."Entry No." := 1;
        OptionRow."Quoted Multiword Cleared" := 'stale value';
        OptionRow.Validate("Quoted Multiword", OptionRow."Quoted Multiword"::"Machine Center");
        OptionRow.Insert(false);

        Assert.AreEqual('Machine Center', OptionRow."Quoted Multiword Name", 'the trigger-derived name field must carry the unquoted member name');
        Assert.AreEqual('', OptionRow."Quoted Multiword Cleared", 'the trigger must have cleared the third field');
    end;
}
