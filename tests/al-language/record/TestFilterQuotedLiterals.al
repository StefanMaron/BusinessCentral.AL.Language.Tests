// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/ui-enter-criteria-filters#filter-on-values-that-contain-symbols
// Scope: in-scope
// Fixtures used: ALT Universal (60000)
// Contract tests: prove how SetFilter treats filter-operator characters that appear
//   literally inside a search value. Per BC docs, values containing & ( ) = | must be
//   enclosed in single quotes to be treated literally; an embedded single quote is
//   escaped by doubling it. The @ (case-insensitive) and * (wildcard) operators stay
//   active inside the quoted expression. Each test must fail if this behavior changes.

codeunit 60199 "Test Filter Quoted Literals"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure SetFilter_UnquotedParenthesis_Throws()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] A '(' in an unquoted filter expression is parsed as an operator and
        //            raises "...Did not expect '('." This is exactly what broke the Concur
        //            candidate page before the value was single-quoted.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'December Expenses (12/01/2025)';
        Rec.Insert();

        // [WHEN] The raw value is concatenated into the filter without quoting
        // [THEN] BC rejects the expression
        asserterror Rec.SetFilter("Description Field", '@*December Expenses (12/01/2025)*');
        Assert.AreNotEqual('', GetLastErrorText(), 'Unquoted "(" in a filter expression must raise an error');
    end;

    [Test]
    procedure SetFilter_QuotedParenthesis_MatchesLiterally()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] The same value, single-quoted, filters literally and matches.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'December Expenses (12/01/2025) - Diana Costa';
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Description Field" := 'January Travel';
        Rec.Insert();

        Rec.SetFilter("Description Field", WrapLiteral('December Expenses (12/01/2025)'));
        Assert.AreEqual(1, Rec.Count(), 'Quoted "(" value must match exactly the one record containing it');
        Rec.FindFirst();
        Assert.AreEqual(1, Rec."Entry No.", 'The matching record must be Entry No. 1');
    end;

    [Test]
    procedure SetFilter_QuotedAmpersand_MatchesLiterally()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] '&' is the filter "And" operator; quoting makes it literal.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'Smith & Sons LLC';
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Description Field" := 'Acme Co';
        Rec.Insert();

        Rec.SetFilter("Description Field", WrapLiteral('Smith & Sons'));
        Assert.AreEqual(1, Rec.Count(), 'Quoted "&" value must match literally');
        Rec.FindFirst();
        Assert.AreEqual(1, Rec."Entry No.", 'The matching record must be Entry No. 1');
    end;

    [Test]
    procedure SetFilter_QuotedPipeAndParens_MatchesLiterally()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] Several operator characters at once (| ( )) must all be literal.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'Reimbursement (Travel|Meals)';
        Rec.Insert();

        Rec.SetFilter("Description Field", WrapLiteral('(Travel|Meals)'));
        Assert.AreEqual(1, Rec.Count(), 'Quoted "|" and "()" must all be treated literally');
    end;

    [Test]
    procedure SetFilter_QuotedDoubledSingleQuote_MatchesLiterally()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] An embedded single quote is escaped by doubling it inside the quoted
        //            expression, so an apostrophe in the data matches literally.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'Diana''s December Expenses'; // stored value contains one apostrophe
        Rec.Insert();

        Rec.SetFilter("Description Field", WrapLiteral('Diana''s December'));
        Assert.AreEqual(1, Rec.Count(), 'Doubled single quote inside the quoted filter must match the apostrophe literally');
    end;

    [Test]
    procedure SetFilter_QuotedExpression_IsCaseInsensitiveWithAt()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] The @ operator remains active inside the single-quoted expression, so
        //            a lower-case search still matches an upper-case stored value.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'DECEMBER EXPENSES (12/01/2025)';
        Rec.Insert();

        Rec.SetFilter("Description Field", WrapLiteral('december expenses (12/01/2025)'));
        Assert.AreEqual(1, Rec.Count(), '@ inside the quoted expression must keep matching case-insensitive');
    end;

    [Test]
    procedure SetFilter_QuotedExpression_StillExcludesNonMatches()
    var
        Rec: Record "ALT Universal";
    begin
        // [SCENARIO] Quoting must not turn the filter into a match-everything: non-matching
        //            records are still excluded.
        Initialize();
        Rec."Entry No." := 1;
        Rec."Description Field" := 'Q1 Expenses (2025)';
        Rec.Insert();
        Rec."Entry No." := 2;
        Rec."Description Field" := 'Q2 Travel';
        Rec.Insert();

        Rec.SetFilter("Description Field", WrapLiteral('(2025)'));
        Assert.AreEqual(1, Rec.Count(), 'Only the record containing the literal substring must match');
        Rec.FindFirst();
        Assert.AreEqual(1, Rec."Entry No.", 'The matching record must be Entry No. 1');
    end;

    // Builds a case-insensitive "contains" filter for an arbitrary literal value:
    // wrap in single quotes so &,(,),=,| are literal, double any embedded single quote,
    // and keep @ and * active. Mirrors the documented BC escaping convention.
    local procedure WrapLiteral(Value: Text): Text
    begin
        exit('''@*' + Value.Replace('''', '''''') + '*''');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
