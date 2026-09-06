// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/
//   dev-itpro/developer/methods-auto/record/record-calcfields-method
// Scope: in-scope
// Fixtures used: CFM Line (60440), CFM Header (60441), ALT Blob (60008)
// BC versions: 27.0+
//
// CLAIM: Record.CalcFields accepts a field only if it is a FlowField carrying a CalcFormula,
// or a BLOB. Everything else is refused at run time, before anything is calculated:
//
//     The <Field> field in the <Table> table must be a FlowField.
//     You must define a CalcFormula for the <Field> FlowField in the <Table> table.
//
// Both refusals are RUNTIME ones, which is the only reason they can be pinned from AL at all.
// alc 17.0.34.45391 emits no diagnostic for `Rec.CalcFields("No.")`, for
// `Rec.CalcFields("Date Filter")`, or for a FlowField declared with no CalcFormula property.
// All three compile and publish; the error appears when the call executes.
//
// The first message names two things that are NOT the same predicate, and the difference is
// half the point of this file:
//
//   * "must be a FlowField"  -- a field CLASS. A FlowFilter field's class is FlowFilter, not
//                               FlowField, so by the wording it should be refused as well.
//                               That is a reading of the wording, so it is measured below
//                               rather than assumed.
//   * a BLOB is accepted     -- but "Blob" is a DATA TYPE, not a field class. A Blob column's
//                               FieldClass is Normal, exactly like the Code and Text columns
//                               that ARE refused, so BLOB acceptance cannot follow from the
//                               field class and has to be pinned on its own.
//
// The BLOB exemption is pinned twice on purpose: alone (it loads its bytes), and named
// alongside an ordinary column in ONE call (the ordinary column is still refused). Without the
// second, a reading where any BLOB in the field list turns the check off entirely would
// survive.
//
// Seeded CFM data (D1): Amounts 40, -10, 75, 20 -- "Total Amount" is 125 over 4 lines.
codeunit 60444 "CalcFields Field Class Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    var
        CfmLine: Record "CFM Line";
        CfmHeader: Record "CFM Header";
    begin
        Cleanup.Initialize();

        CfmLine.Reset();
        CfmLine.DeleteAll();
        CfmHeader.Reset();
        CfmHeader.DeleteAll();

        CfmHeader.Init();
        CfmHeader."No." := 'D1';
        CfmHeader.Insert(false);

        AddLine(1, 'D1', 40);
        AddLine(2, 'D1', -10);
        AddLine(3, 'D1', 75);
        AddLine(4, 'D1', 20);
    end;

    local procedure AddLine(EntryNo: Integer; DocNo: Code[20]; Amt: Decimal)
    var
        CfmLine: Record "CFM Line";
    begin
        CfmLine.Init();
        CfmLine."Entry No." := EntryNo;
        CfmLine."Doc No." := DocNo;
        CfmLine.Amount := Amt;
        CfmLine.Insert(false);
    end;

    local procedure SeedBlob(No: Code[20]; Payload: Text)
    var
        AltBlob: Record "ALT Blob";
        OutStr: OutStream;
    begin
        AltBlob.Init();
        AltBlob.Code := No;
        AltBlob.Description := 'SEEDED';
        AltBlob.Insert(false);

        Clear(AltBlob.Data);
        AltBlob.Data.CreateOutStream(OutStr);
        OutStr.WriteText(Payload);
        AltBlob.Modify(false);
    end;

    [Test]
    procedure Record_CalcFields_NormalKeyField_Throws()
    // CLAIM: the primary key column -- an ordinary stored Code field -- is refused, and the
    //        message names the field and its table.
    var
        CfmHeader: Record "CFM Header";
    begin
        Initialize();
        CfmHeader.Get('D1');

        asserterror CfmHeader.CalcFields("No.");

        Assert.ExpectedError('The No. field in the CFM Header table must be a FlowField.');
    end;

    [Test]
    procedure Record_CalcFields_NormalTextFieldOnAnotherTable_Throws()
    // CLAIM: the refusal is not particular to a key, a type or a table -- an ordinary Text
    //        column on an unrelated table is refused with the same wording, naming ITS table.
    var
        AltBlob: Record "ALT Blob";
    begin
        Initialize();
        SeedBlob('B1', 'PAYLOAD-ONE');
        AltBlob.Get('B1');

        asserterror AltBlob.CalcFields(Description);

        Assert.ExpectedError('The Description field in the ALT Blob table must be a FlowField.');
    end;

    [Test]
    procedure Record_CalcFields_FlowFilterField_Throws()
    // CLAIM: a FlowFilter field is refused too. Its FieldClass is FlowFilter rather than
    //        Normal, so this separates "the check is FieldClass = FlowField" from the weaker
    //        "ordinary stored columns are refused".
    var
        CfmHeader: Record "CFM Header";
    begin
        Initialize();
        CfmHeader.Get('D1');

        asserterror CfmHeader.CalcFields("Date Filter");

        Assert.ExpectedError('The Date Filter field in the CFM Header table must be a FlowField.');
    end;

    [Test]
    procedure Record_CalcFields_FlowFieldWithoutCalcFormula_Throws()
    // CLAIM: being a FlowField is not enough -- a FlowField declared with no CalcFormula is
    //        refused too, with its own wording. "Unformulated Amount" (field 30 on CFM Header)
    //        exists only for this, and alc accepts the declaration, so the shape is reachable.
    var
        CfmHeader: Record "CFM Header";
    begin
        Initialize();
        CfmHeader.Get('D1');

        asserterror CfmHeader.CalcFields("Unformulated Amount");

        Assert.ExpectedError(
          'You must define a CalcFormula for the Unformulated Amount FlowField in the CFM Header table.');
    end;

    [Test]
    procedure Record_CalcFields_BlobField_LoadsTheStoredBytes()
    // CLAIM: a Blob column IS accepted, even though its FieldClass is Normal exactly like the
    //        Code and Text columns refused above. The assertion is the seeded payload, so a
    //        CalcFields that silently did nothing reads '' and fails.
    var
        AltBlob: Record "ALT Blob";
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();
        SeedBlob('B1', 'PAYLOAD-ONE');

        AltBlob.Get('B1');
        AltBlob.CalcFields(Data);

        AltBlob.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('PAYLOAD-ONE', ReadBack, 'CalcFields on a Blob field must load the stored bytes');
    end;

    [Test]
    procedure Record_CalcFields_BlobAlongsideNormalField_ThrowsForTheNormalField()
    // CLAIM: the BLOB exemption is per field, not per call -- naming a Blob in the same
    //        CalcFields as an ordinary column does not make the ordinary column acceptable.
    var
        AltBlob: Record "ALT Blob";
        InStr: InStream;
        ReadBack: Text;
    begin
        Initialize();
        SeedBlob('B1', 'PAYLOAD-ONE');
        AltBlob.Get('B1');

        // [WHEN] One call names the accepted Blob AND an ordinary Text column.
        asserterror AltBlob.CalcFields(Data, Description);

        // [THEN] Refused, and the message names the ordinary column rather than the Blob.
        Assert.ExpectedError('The Description field in the ALT Blob table must be a FlowField.');

        // [THEN] The control: the same Blob named on its own still loads, so the refusal above
        //        is the ordinary column and not a broken fixture. asserterror rolls the write
        //        transaction back, which takes the seeded row with it, so the seed is laid
        //        down again first.
        Initialize();
        SeedBlob('B1', 'PAYLOAD-ONE');
        AltBlob.Get('B1');
        AltBlob.CalcFields(Data);

        AltBlob.Data.CreateInStream(InStr);
        InStr.ReadText(ReadBack);
        Assert.AreEqual('PAYLOAD-ONE', ReadBack, 'a Blob named on its own must still load after the refusal above');
    end;

    [Test]
    procedure Record_CalcFields_NormalFieldAlongsideValidFlowField_CalculatesNeither()
    // CLAIM: BC refuses the whole call before it aggregates anything, so a valid FlowField
    //        named alongside a refused ordinary field is left uncalculated.
    var
        CfmHeader: Record "CFM Header";
    begin
        // [GIVEN] D1, whose "Total Amount" is 125 and "Line Count" is 4.
        Initialize();
        CfmHeader.Get('D1');

        // [WHEN] One CalcFields names two valid FlowFields and one ordinary column.
        asserterror CfmHeader.CalcFields("Total Amount", "Line Count", "No.");

        // [THEN] The call is refused.
        Assert.ExpectedError('The No. field in the CFM Header table must be a FlowField.');

        // [THEN] And neither valid FlowField was left calculated. The record variable is NOT
        // re-read here -- re-reading would reset every FlowField to 0 and make this vacuous --
        // so these read the same buffer the refused call was handed.
        Assert.AreEqual(0, CfmHeader."Total Amount",
          'a refused CalcFields must not leave the valid sum() calculated');
        Assert.AreEqual(0, CfmHeader."Line Count",
          'a refused CalcFields must not leave the valid count() calculated');

        // [THEN] The control: named without the ordinary column, those same two calculate to
        // 125 and 4. The seed is laid down again because asserterror rolled back the four D1
        // lines; the rollback does not weaken the zeros above, since it discards database rows
        // and not the record variable's FlowField buffer.
        Initialize();
        CfmHeader.Get('D1');
        CfmHeader.CalcFields("Total Amount", "Line Count");
        Assert.AreEqual(125, CfmHeader."Total Amount",
          'the valid sum() must calculate when not named alongside an ordinary field');
        Assert.AreEqual(4, CfmHeader."Line Count",
          'the valid count() must calculate when not named alongside an ordinary field');
    end;
}
