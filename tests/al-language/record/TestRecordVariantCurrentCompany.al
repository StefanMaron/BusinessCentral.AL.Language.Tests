// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-currentcompany-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000); reuses the company 'ALT CHGCO ROWS' and the shared
//                steps in "ALT ChangeCompany Lib" (69972) from TestRecordChangeCompanyRows.al
// BC versions: 27.0+
//
// CLAIM UNDER TEST: the company a record is pointed at by ChangeCompany is NOT carried through a
// Variant.
//   * RecordRef: GetTable(Variant) yields a reference on the session company, while GetTable on
//     the record itself keeps the other company. The loss is the Variant hop.
//   * Typed Record: assignment never moves a record variable to another company, with or without
//     a Variant. A fresh target assigned from the boxed record is on the session company, a direct
//     assignment gives the same answer, and a target already pointed at the other company stays
//     there when it is assigned from a session-company record. The company belongs to the
//     variable, not to the value.
//   * Passing the record itself by var keeps the company; passing the Variant by value into a
//     procedure loses it there too.
// The working pattern the harness uses — GetTable from the Variant and then ChangeCompany again on
// the reference — reads the other company's rows.
//
// The other company is provisioned ONCE for the whole codeunit (provisioning a company creates
// all of its tables and the harness stops a codeunit after ten minutes), so every claim is proven
// in a single test rather than one-company-per-codeunit.
//
// Measured on W1 sandboxes BC 27.0 (27.0.38460.56409), 28.5 (28.5.54151.56408) and 29.0
// (29.0.54011.55816): every assertion holds unchanged on all three, so no version guard.

codeunit 69503 "Test RecVariant Company"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Lib: Codeunit "ALT ChangeCompany Lib";

    [Test]
    procedure RecVariant_CompanyAssociation_IsNotCarried()
    var
        Home: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        Direct: Record "ALT Universal";
        OnOther: Record "ALT Universal";
        SessionRec: Record "ALT Universal";
        SessionRow: Record "ALT Universal";
        OtherRow: Record "ALT Universal";
        RecRef: RecordRef;
        DirectRef: RecordRef;
        ReadRef: RecordRef;
        V: Variant;
        SessionV: Variant;
    begin
        Lib.Cleanup();
        Lib.InsertCompany();    // provision the other company once for this codeunit

        // GIVEN a record pointed at the other company
        Assert.IsTrue(Home.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany to the inserted company');
        Assert.AreEqual(Lib.CompanyNameUnderTest(), Home.CurrentCompany(), 'baseline: the record is on the other company');

        // WHEN boxed into a Variant and taken back as a RecordRef via GetTable
        // THEN the reference drops back to the session company
        V := Home;
        RecRef.GetTable(V);
        Assert.AreEqual(CompanyName(), RecRef.CurrentCompany(), 'the company must NOT cross Variant + GetTable — the reference is on the session company');
        RecRef.Close();

        // CONTROL: GetTable on the record itself keeps the other company, so the loss above is the
        // Variant hop and not GetTable
        DirectRef.GetTable(Home);
        Assert.AreEqual(Lib.CompanyNameUnderTest(), DirectRef.CurrentCompany(), 'GetTable(Record) keeps the other company');
        DirectRef.Close();

        // WHEN boxed and taken back as a typed Record, THEN it is on the session company too
        Rec2 := V;
        Assert.AreEqual(CompanyName(), Rec2.CurrentCompany(), 'the company must NOT cross the Variant round trip onto a typed Record — it is on the session company');

        // AND a direct assignment gives the same answer: for a typed Record the company is the
        // variable's, so the Variant adds no loss of its own
        Direct := Home;
        Assert.AreEqual(CompanyName(), Direct.CurrentCompany(), 'a direct assignment does not move the target to the other company either');

        // AND a target already on the other company stays there when assigned from a session-company record
        Assert.IsTrue(OnOther.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany for the target');
        SessionV := SessionRec;
        OnOther := SessionV;
        Assert.AreEqual(Lib.CompanyNameUnderTest(), OnOther.CurrentCompany(), 'assignment from a Variant leaves the target on the company it was pointed at');

        // CONTROL: passing the record itself by var keeps the other company
        Assert.AreEqual(Lib.CompanyNameUnderTest(), CompanyOfByRef(Home), 'passing the record by var keeps the other company');

        // AND passing the Variant by value into a procedure loses the company there too — GetTable
        // inside the callee reports the session company, not the other one
        Assert.AreEqual(CompanyName(), CompanyViaGetTable(V), 'a Variant passed by value into a procedure loses the company — the callee is on the session company');

        // AND the working pattern — GetTable from the Variant, then ChangeCompany on the reference —
        // reads the other company's own rows, separate from the session company's
        SessionRow.Init();
        SessionRow."Entry No." := 1;
        SessionRow."Integer Field" := 11;
        SessionRow.Insert();

        Assert.IsTrue(OtherRow.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany for the row written into the other company');
        OtherRow.Init();
        OtherRow."Entry No." := 1;
        OtherRow."Integer Field" := 77;
        OtherRow.Insert();

        V := OtherRow;
        ReadRef.GetTable(V);
        Assert.IsTrue(ReadRef.ChangeCompany(Lib.CompanyNameUnderTest()), 'ChangeCompany again on the reference after GetTable(Variant)');
        Assert.AreEqual(1, ReadRef.Count(), 'the reference reads the other company''s one row');
        Assert.IsTrue(ReadRef.FindFirst(), 'and can position on it');
        Assert.AreEqual(77, ReadRef.Field(3).Value(), 'and reads its value, not the session company''s');
        ReadRef.Close();

        SessionRow.Get(1);
        Assert.AreEqual(11, SessionRow."Integer Field", 'the session company keeps its own row');

        Lib.Cleanup();
    end;

    local procedure CompanyOfByRef(var R: Record "ALT Universal"): Text[30]
    begin
        exit(R.CurrentCompany());
    end;

    local procedure CompanyViaGetTable(V: Variant): Text[30]
    var
        RecRef: RecordRef;
        Result: Text[30];
    begin
        RecRef.GetTable(V);
        Result := RecRef.CurrentCompany();
        RecRef.Close();
        exit(Result);
    end;
}
