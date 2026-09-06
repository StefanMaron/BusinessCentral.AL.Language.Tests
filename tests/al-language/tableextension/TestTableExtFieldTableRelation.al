// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none - Base Application's own Customer (18), Service Zone (5957) and
//   Territory (286) tables; shared Assert (60021)
// BC versions: 27.0+
//
// CLAIM: a TableRelation contributed by a TABLEEXTENSION is enforced by Validate exactly as
// one declared on the base table is. Nothing about the enforcement depends on where the
// relation was declared.
//
// The corpus already asserts that BC enforces a TableRelation, but only on fields declared
// on a plain table (fieldref/TestFieldRefRelation.al, access-control/TestUserTableSessionUser.al).
// Neither of those touches a tableextension, so "BC enforces a relation a tableextension added"
// was not pinned anywhere.
//
// SUBJECT: Customer 5900 "Service Zone Code" (Code[10], TableRelation = "Service Zone"),
// contributed by tableextension 6450 "Serv. Customer" shipped INSIDE the Base Application
// package. It is not on Customer's own field list. It is the right subject because it carries
// neither an OnValidate trigger nor a ValidateTableRelation property, so the relation check is
// the only thing in Validate that can raise -- unlike Item."Routing No." (an OnValidate calling
// TestField and PlanningAssignment) or "Requisition Line"."Prod. Order No." (both an OnValidate
// and a ValidateTableRelation), either of which could refuse a value for an unrelated reason.
//
// CONTROL: Customer 15 "Territory Code" (Code[10], TableRelation = Territory), declared on the
// BASE table 18 itself and structurally identical -- Code[10], plain single-arm relation to a
// two-field code table, no trigger, no ValidateTableRelation. The two pairs of tests differ in
// exactly one thing: which object declared the relation. That is what makes "exactly as one
// declared on the base table" an assertion rather than a phrase.
//
// WHY THIS CANNOT PASS VACUOUSLY: within each pair the SAME code value is fed to the SAME
// field, and the only thing that changes between the two tests is whether the related row
// exists. So an implementation that refused every value fails the accepting test, and one that
// checked nothing fails the refusing test. The accepting test also pins that the relation
// resolved to the RIGHT related table -- inserting a "Service Zone" row would not rescue a
// relation that had resolved to some other table. The last test adds the third direction: a
// direct assignment of the same unrelated value is NOT refused, so the refusal above comes from
// Validate's relation check and not from the value, the field length, or the field itself.
//
// The Customer buffer is never inserted -- Init() plus Validate() is the whole scenario -- so no
// number series, no insert trigger and no customer master data is involved. Initialize()
// therefore deletes only the two related-table rows this codeunit creates (filtered on ALTTR*)
// and never touches Customer, whose rows belong to the company, not to this test.
codeunit 60827 "Test TableExt Field Relation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TableExt_Validate_ContributedRelation_NoRelatedRow_Throws()
    // CLAIM: Validate on a field whose TableRelation came from a tableextension refuses a value
    // that has no row in the related table.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] No "Service Zone" row carries this code (Initialize deleted it).
        Clear(Cust);
        Cust.Init();

        // [WHEN/THEN] Validating the tableextension-contributed field with it is refused.
        asserterror Cust.Validate("Service Zone Code", 'ALTTRZONE1');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure TableExt_Validate_ContributedRelation_RelatedRowExists_AssignsTheValue()
    // CLAIM: the SAME value the test above refused is accepted once the related row exists, so
    // the refusal was the relation check and not a blanket rejection.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] A "Service Zone" row with exactly the code the previous test was refused.
        InsertServiceZone('ALTTRZONE1');

        // [WHEN] The tableextension-contributed field is validated with it.
        Clear(Cust);
        Cust.Init();
        Cust.Validate("Service Zone Code", 'ALTTRZONE1');

        // [THEN] Validate succeeds and the field holds the value.
        Assert.AreEqual(
            'ALTTRZONE1', Cust."Service Zone Code",
            'Validate must accept a value that exists in the table the tableextension-contributed ' +
            'TableRelation points at, and store it');
    end;

    [Test]
    procedure TableExt_Validate_BaseTableRelation_NoRelatedRow_Throws()
    // CLAIM: control -- a relation declared on the BASE table refuses an unrelated value the
    // same way, so the pair above is measuring the relation and not something about Customer.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] No Territory row carries this code (Initialize deleted it).
        Clear(Cust);
        Cust.Init();

        // [WHEN/THEN] Validating the base-table-declared field with it is refused, with the
        // same error the tableextension-contributed field raised.
        asserterror Cust.Validate("Territory Code", 'ALTTRTERR1');
        Assert.ExpectedError('cannot be found in the related table');
    end;

    [Test]
    procedure TableExt_Validate_BaseTableRelation_RelatedRowExists_AssignsTheValue()
    // CLAIM: control -- the base-table-declared relation accepts the same value once the
    // related row exists.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] A Territory row with exactly the code the previous test was refused.
        InsertTerritory('ALTTRTERR1');

        // [WHEN] The base-table-declared field is validated with it.
        Clear(Cust);
        Cust.Init();
        Cust.Validate("Territory Code", 'ALTTRTERR1');

        // [THEN] Validate succeeds and the field holds the value.
        Assert.AreEqual(
            'ALTTRTERR1', Cust."Territory Code",
            'Validate must accept a value that exists in the table the base-table-declared ' +
            'TableRelation points at, and store it');
    end;

    [Test]
    procedure TableExt_Assign_ContributedRelation_NoRelatedRow_IsNotChecked()
    // CLAIM: a direct assignment bypasses the tableextension-contributed relation entirely, so
    // the refusal in the first test is Validate's relation check -- not the value, and not the
    // field.
    var
        Cust: Record Customer;
    begin
        Initialize();

        // [GIVEN] No "Service Zone" row carries this code.
        Clear(Cust);
        Cust.Init();

        // [WHEN] The value is assigned directly rather than validated.
        Cust."Service Zone Code" := 'ALTTRZONE1';

        // [THEN] The assignment stands -- no relation check ran.
        Assert.AreEqual(
            'ALTTRZONE1', Cust."Service Zone Code",
            'A direct assignment must not consult the tableextension-contributed TableRelation');
    end;

    local procedure Initialize()
    var
        ServiceZone: Record "Service Zone";
        Terr: Record Territory;
    begin
        // Only this codeunit's own rows: Customer, Service Zone and Territory are company data,
        // and a blanket DeleteAll on them would destroy rows this test did not create. No
        // Customer row is ever written, so none has to be removed.
        ServiceZone.Reset();
        ServiceZone.SetFilter(Code, 'ALTTR*');
        ServiceZone.DeleteAll(false);

        Terr.Reset();
        Terr.SetFilter(Code, 'ALTTR*');
        Terr.DeleteAll(false);
    end;

    local procedure InsertServiceZone(ZoneCode: Code[10])
    var
        ServiceZone: Record "Service Zone";
    begin
        ServiceZone.Init();
        ServiceZone.Code := ZoneCode;
        ServiceZone.Description := 'Relation subject';
        ServiceZone.Insert(false);
    end;

    local procedure InsertTerritory(TerritoryCode: Code[10])
    var
        Terr: Record Territory;
    begin
        Terr.Init();
        Terr.Code := TerritoryCode;
        Terr.Name := 'Relation control';
        Terr.Insert(false);
    end;
}
