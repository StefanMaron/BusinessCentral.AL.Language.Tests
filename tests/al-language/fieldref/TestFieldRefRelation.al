// FieldRef.Relation — the related table's object id for the arm that currently applies.
//
// BC evaluates a field's TableRelation arms against the CURRENT record buffer and answers the
// id of the first arm whose if() conditions hold; a field with no TableRelation answers 0. The
// where() clause narrows which ROWS of the related table are valid, so it does not change the
// answer here — but a relation that carries one must still answer, and that is the case
// nothing in this corpus covered.
//
// The BC-side answers asserted here are concrete table ids (60480, 60030, 225, 0), never
// "non-zero", so an implementation that answered a fixed value could not pass.

codeunit 60482 "Test FieldRef Relation"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure FieldRef_Relation_PlainRelation_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Where Child");
        FldRef := RecRef.Field(6);

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", FldRef.Relation(),
            'a field declaring TableRelation = "ALT Rel Where Parent"."Code" must answer table 60480');
    end;

    [Test]
    procedure FieldRef_Relation_RelationWithWhereFieldLink_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();

        // The subject. The where() clause restricts which parent ROWS are valid; it does not
        // make the relation itself unanswerable, so Relation is the same table id the plain
        // shape above answers.
        RecRef.Open(Database::"ALT Rel Where Child");
        FldRef := RecRef.Field(4);

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", FldRef.Relation(),
            'a TableRelation narrowed by where("Group Code" = field("Group Code")) must still ' +
            'answer the related table id 60480');
    end;

    [Test]
    procedure FieldRef_Relation_FieldWithoutTableRelation_ReturnsZero()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();

        // The negative direction, and the reason the assertions above have to name concrete
        // ids: 0 is what "no relation declared" means, so it must stay reachable.
        RecRef.Open(Database::"ALT Rel Where Child");
        FldRef := RecRef.Field(7);

        Assert.AreEqual(
            0, FldRef.Relation(),
            'a field declaring no TableRelation must answer 0');
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalWithWhereFieldLink_SelectsTheIfArm()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KindRef: FieldRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Where Child");
        KindRef := RecRef.Field(3);
        KindRef.Value := 0; // Kind::A — the if() arm, which is the one carrying the where()

        FldRef := RecRef.Field(5);

        Assert.AreEqual(
            Database::"ALT Rel Where Parent", FldRef.Relation(),
            'with Kind = A the if() arm applies, so Relation must answer its target (60480)');
    end;

    [Test]
    procedure FieldRef_Relation_ConditionalWithWhereFieldLink_SelectsTheElseArm()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        KindRef: FieldRef;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Rel Where Child");
        KindRef := RecRef.Field(3);
        KindRef.Value := 1; // Kind::B — the else arm, a different target table

        FldRef := RecRef.Field(5);

        // A different id from the test above, on the same field of the same record — so an
        // implementation that answered the first arm regardless of the record's state fails
        // exactly one of the two.
        Assert.AreEqual(
            Database::"ALT Relation Parent B", FldRef.Relation(),
            'with Kind = B the else arm applies, so Relation must answer its target (60030)');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationFieldWithWhereFieldLink_ReturnsRelatedTableId()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Cust: Record Customer;
    begin
        Initialize();

        // The same shape on a table this app does not declare. Customer.City is
        //   if ("Country/Region Code" = const('')) "Post Code".City
        //   else if ("Country/Region Code" = filter(<> '')) "Post Code".City
        //        where("Country/Region Code" = field("Country/Region Code"))
        // and on a blank record the FIRST arm applies. Both arms name Post Code, so the answer
        // does not depend on which one BC picks — only on the whole property being readable.
        RecRef.Open(Database::Customer);
        FldRef := RecRef.Field(Cust.FieldNo(City));

        Assert.AreEqual(
            Database::"Post Code", FldRef.Relation(),
            'Customer.City declares TableRelation = "Post Code".City in both arms, so ' +
            'FieldRef.Relation must answer table 225');
    end;

    [Test]
    procedure FieldRef_Relation_BaseApplicationFieldWithoutTableRelation_ReturnsZero()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        Cust: Record Customer;
    begin
        Initialize();

        // Control for the test above on the same table: Customer.Name declares no
        // TableRelation, so "every Base Application field answers non-zero" cannot pass.
        RecRef.Open(Database::Customer);
        FldRef := RecRef.Field(Cust.FieldNo(Name));

        Assert.AreEqual(
            0, FldRef.Relation(),
            'Customer.Name declares no TableRelation, so FieldRef.Relation must answer 0');
    end;

    [Test]
    procedure Validate_RelationWithWhereFieldLink_RefusesARowOutsideTheFilter()
    var
        Parent: Record "ALT Rel Where Parent";
        Child: Record "ALT Rel Where Child";
    begin
        Initialize();

        Parent.Init();
        Parent."Code" := 'P-OTHER';
        Parent."Group Code" := 'G2';
        Parent.Insert();

        Child.Init();
        Child."Entry No." := 1;
        Child."Group Code" := 'G1';

        // P-OTHER exists, so this can only be refused because the where() clause narrowed the
        // related rows to Group Code = G1 — which is what makes the field() link observable
        // rather than decorative.
        asserterror Child.Validate("Where Field Ref", 'P-OTHER');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure Validate_RelationWithWhereFieldLink_AcceptsARowInsideTheFilter()
    var
        Parent: Record "ALT Rel Where Parent";
        Child: Record "ALT Rel Where Child";
    begin
        Initialize();

        Parent.Init();
        Parent."Code" := 'P-SAME';
        Parent."Group Code" := 'G1';
        Parent.Insert();

        Child.Init();
        Child."Entry No." := 1;
        Child."Group Code" := 'G1';

        // The positive direction of the test above: a relation that refused everything would
        // pass that one and fail this one.
        Child.Validate("Where Field Ref", 'P-SAME');

        Assert.AreEqual('P-SAME', Child."Where Field Ref",
            'a parent row inside the where() filter must be accepted and stored');
    end;
}
