// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-optioncaption-property
// Scope: in-scope
// Fixtures used: Base Application table 2582 "Dimension Correction" and page 2592 "Dimension Corrections"
//
// A table field's OptionCaption is what BC answers wherever an Option field is shown as text,
// including when the table reaches the test precompiled inside a dependency app and the page
// control bound to it declares no OptionCaption of its own. Table 2582's Status declares the
// member "Validaton in Process" (sic) and the caption 'Validation in Process', so a runtime
// that falls back to the member names cannot satisfy any assertion below:
//   * FieldRef.OptionCaption answers the caption list; FieldRef.OptionMembers keeps the names.
//   * Format() of the value answers its caption.
//   * Evaluate() accepts the caption and selects that member.
//   * page 2592's Status control declares no OptionCaption, so TestPage Value() answers the
//     table field's caption.
//   * Evaluate() of text that is neither refuses, and its message lists the captions.

codeunit 67600 "Precompiled Field Opt Caption"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        CaptionListTxt: Label 'Draft,In Process,Validation in Process,Failed,Completed,Undo in Process,Undo Completed', Locked = true;
        MemberListTxt: Label 'Draft,In Process,Validaton in Process,Failed,Completed,Undo in Process,Undo Completed', Locked = true;

    [Test]
    procedure FieldRef_OptionCaption_AnswersTheTableFieldCaption()
    var
        DimCorrection: Record "Dimension Correction";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(Database::"Dimension Correction");
        FldRef := RecRef.Field(DimCorrection.FieldNo(Status));

        Assert.AreEqual(CaptionListTxt, FldRef.OptionCaption(),
            'FieldRef.OptionCaption must answer the field''s declared OptionCaption');
        Assert.AreEqual(MemberListTxt, FldRef.OptionMembers(),
            'FieldRef.OptionMembers must still answer the member names, typo included');
    end;

    [Test]
    procedure Format_OptionValue_AnswersItsCaption()
    var
        DimCorrection: Record "Dimension Correction";
    begin
        DimCorrection.Status := DimCorrection.Status::"Validaton in Process";

        Assert.AreEqual('Validation in Process', Format(DimCorrection.Status),
            'Format of the option must answer its caption, not its member name');
    end;

    [Test]
    procedure Evaluate_Caption_SelectsThatMember()
    var
        DimCorrection: Record "Dimension Correction";
    begin
        Assert.IsTrue(Evaluate(DimCorrection.Status, 'Validation in Process'),
            'Evaluate must accept the option''s caption');

        Assert.AreEqual(DimCorrection.Status::"Validaton in Process", DimCorrection.Status,
            'Evaluating the caption must select the member it captions');
    end;

    [Test]
    procedure Evaluate_UnknownText_IsRefusedListingTheCaptions()
    var
        DimCorrection: Record "Dimension Correction";
    begin
        asserterror Evaluate(DimCorrection.Status, 'Not A Status');

        Assert.IsTrue(StrPos(GetLastErrorText(), 'Not A Status') > 0,
            'the refusal must name the text it refused; got: ' + GetLastErrorText());
        Assert.IsTrue(StrPos(GetLastErrorText(), 'Validation in Process') > 0,
            'the refusal must list the option''s captions; got: ' + GetLastErrorText());
    end;

    [Test]
    procedure TestPage_Value_AnswersTheTableFieldCaption()
    var
        DimCorrection: Record "Dimension Correction";
        DimCorrections: TestPage "Dimension Corrections";
    begin
        DimCorrection.DeleteAll();
        DimCorrection.Init();
        DimCorrection.Insert(true);
        DimCorrection.Status := DimCorrection.Status::"Validaton in Process";
        DimCorrection.Modify();

        DimCorrections.OpenView();
        Assert.IsTrue(DimCorrections.GoToRecord(DimCorrection), 'the inserted correction must be on the page');

        Assert.AreEqual('Validation in Process', DimCorrections.Status.Value(),
            'the control declares no OptionCaption, so Value() must answer the table field''s caption');
        DimCorrections.Close();
    end;
}
