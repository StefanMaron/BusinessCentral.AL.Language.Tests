// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: ALT Relation Child (60029), ALT Relation Parent (60028), ALT Relation Parent B (60030);
//                Base Application "Sales Line" (37) and Item (27)
// BC versions: 27.5+
//
// Pins the built-in "Table Relations Metadata" system virtual table (2000000141): one row per
// (table, field, relation, condition) computed from each field's TableRelation property. Base
// Application reads it to find the table and field a lookup should open -- "Config. Template
// Management".GetLookupParameters starts with
//
//     TableRelationsMetadata.SetRange("Table ID", ...); SetRange("Field No.", ...);
//     if TableRelationsMetadata.IsEmpty() then exit;
//
// so a table that answers no rows makes that code return without opening anything, silently.
//
// IsEmpty, Count and FindSet are asserted separately on purpose: they reach a data provider by
// different paths, and one answering correctly says nothing about the others.
//
// Negative cases carry as much weight as the positive ones: a provider that answered the same
// rows for every field would pass the positive tests alone, so a field with no TableRelation
// (ALT Relation Child."Soft Ref") must answer no rows.
//
// The last test reads a Base Application table, so the rows come from a precompiled app's
// metadata rather than from this app's source.

codeunit 60982 "Test Table Relations Metadata"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_TableRelationsMetadata_PlainRelation_YieldsOneRowNamingTheRelatedTable()
    // CLAIM: a field with an unconditional TableRelation has exactly one row, naming the
    // related table and its primary-key field.
    var
        Relations: Record "Table Relations Metadata";
        Child: Record "ALT Relation Child";
    begin
        Initialize();

        Relations.SetRange("Table ID", Database::"ALT Relation Child");
        Relations.SetRange("Field No.", Child.FieldNo("Validated Ref"));

        Assert.IsFalse(Relations.IsEmpty(), 'IsEmpty: a field declaring a TableRelation must have a Table Relations Metadata row');
        Assert.AreEqual(1, Relations.Count(), 'Count: an unconditional TableRelation is one row');
        Assert.IsTrue(Relations.FindFirst(), 'FindFirst: the row must be readable');
        Assert.AreEqual(Database::"ALT Relation Parent", Relations."Related Table ID", 'Related Table ID');
        Assert.AreEqual(1, Relations."Related Field No.", 'Related Field No. -- ALT Relation Parent.Code is field 1');
        Assert.AreEqual(1, Relations."Relation No.", 'Relation No.');
    end;

    [Test]
    procedure Record_TableRelationsMetadata_FieldWithoutRelation_YieldsNoRows()
    // CLAIM: a field that declares no TableRelation has no rows, by IsEmpty, Count and Find.
    var
        Relations: Record "Table Relations Metadata";
        Child: Record "ALT Relation Child";
    begin
        Initialize();

        Relations.SetRange("Table ID", Database::"ALT Relation Child");
        Relations.SetRange("Field No.", Child.FieldNo("Soft Ref"));

        Assert.IsTrue(Relations.IsEmpty(), 'IsEmpty: "Soft Ref" declares no TableRelation');
        Assert.AreEqual(0, Relations.Count(), 'Count: "Soft Ref" declares no TableRelation');
        Assert.IsFalse(Relations.FindFirst(), 'FindFirst: "Soft Ref" declares no TableRelation');
    end;

    [Test]
    procedure Record_TableRelationsMetadata_IfElseRelation_YieldsOneRowPerBranchInOrder()
    // CLAIM: `if (Kind = const(A)) Parent else Parent B` is two relations, numbered in
    // declaration order, each naming its own related table.
    var
        Relations: Record "Table Relations Metadata";
        Child: Record "ALT Relation Child";
    begin
        Initialize();

        Relations.SetRange("Table ID", Database::"ALT Relation Child");
        Relations.SetRange("Field No.", Child.FieldNo("Conditional Ref"));

        Assert.AreEqual(2, Relations.Count(), 'Count: an if/else TableRelation is two relations');
        Assert.IsTrue(Relations.FindSet(), 'FindSet: the rows must be readable');
        Assert.AreEqual(1, Relations."Relation No.", 'first row Relation No.');
        Assert.AreEqual(Database::"ALT Relation Parent", Relations."Related Table ID", 'first row names the if-branch table');
        Assert.AreEqual(Child.FieldNo(Kind), Relations."Condition Field No.", 'first row is conditioned on Kind');
        Assert.AreEqual(1, Relations.Next(), 'a second row must follow');
        Assert.AreEqual(2, Relations."Relation No.", 'second row Relation No.');
        Assert.AreEqual(Database::"ALT Relation Parent B", Relations."Related Table ID", 'second row names the else-branch table');
        Assert.AreEqual(0, Relations.Next(), 'no third row');
    end;

    [Test]
    procedure Record_TableRelationsMetadata_RelatedTableFilter_SelectsTheMatchingBranch()
    // CLAIM: filtering on "Related Table ID" as well selects only the relation to that table --
    // the second step GetLookupParameters takes.
    var
        Relations: Record "Table Relations Metadata";
        Child: Record "ALT Relation Child";
    begin
        Initialize();

        Relations.SetRange("Table ID", Database::"ALT Relation Child");
        Relations.SetRange("Field No.", Child.FieldNo("Conditional Ref"));
        Relations.SetRange("Related Table ID", Database::"ALT Relation Parent B");

        Assert.AreEqual(1, Relations.Count(), 'Count: exactly one branch relates to ALT Relation Parent B');
        Assert.IsTrue(Relations.FindFirst(), 'FindFirst');
        Assert.AreEqual(2, Relations."Relation No.", 'the else branch is relation 2');
    end;

    [Test]
    procedure Record_TableRelationsMetadata_BaseApplicationTable_YieldsItsConditionalRelations()
    // CLAIM: a Base Application table's relations are served too. Sales Line."No." relates to
    // Item when Type = Item, so a row with Related Table ID = Item exists, is conditioned on
    // Type, and names Item's primary-key field.
    var
        Relations: Record "Table Relations Metadata";
        SalesLine: Record "Sales Line";
        Item: Record Item;
    begin
        Initialize();

        Relations.SetRange("Table ID", Database::"Sales Line");
        Relations.SetRange("Field No.", SalesLine.FieldNo("No."));
        Assert.IsFalse(Relations.IsEmpty(), 'IsEmpty: Sales Line."No." declares a TableRelation');
        Assert.IsTrue(Relations.Count() > 1, 'Count: Sales Line."No." relates to a different table per Type');

        Relations.SetRange("Related Table ID", Database::Item);
        Assert.IsTrue(Relations.FindFirst(), 'a relation from Sales Line."No." to Item must exist');
        Assert.AreEqual(Item.FieldNo("No."), Relations."Related Field No.", 'Related Field No. is Item."No."');
        Assert.AreEqual(SalesLine.FieldNo(Type), Relations."Condition Field No.", 'the Item relation is conditioned on Type');
    end;

    local procedure Initialize()
    begin
        // Table Relations Metadata is a read-only system virtual table -- nothing to DeleteAll.
    end;
}
