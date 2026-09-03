// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-tablecaption-method
// Scope: in-scope
// Fixtures used: ALT Captioned (60830), ALT Universal (60000)
//
// TestRecordRecordId and TestRecordTriggers already call TableCaption(), but both
// only assert it is non-empty, and both use ALT Universal, which declares no
// Caption. Neither can tell a correct caption apart from the object name. These
// tests separate the two: ALT Captioned's name and Caption are different strings.

codeunit 60831 "Test Record TableCaption"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_TableCaption_DeclaredCaption_ReturnsTheCaption()
    var
        Rec: Record "ALT Captioned";
    begin
        Assert.AreEqual(
            'Captioned Fixture Table',
            Rec.TableCaption(),
            'TableCaption() must return the table''s declared Caption');
    end;

    [Test]
    procedure Record_TableName_DeclaredCaption_StillReturnsTheName()
    var
        Rec: Record "ALT Captioned";
    begin
        // Negative direction: TableName() is unaffected by the Caption. Without this,
        // an implementation that answered both from the caption would pass the test
        // above.
        Assert.AreEqual(
            'ALT Captioned',
            Rec.TableName(),
            'TableName() must return the object name, not the declared Caption');
    end;

    [Test]
    procedure Record_TableCaption_NoDeclaredCaption_ReturnsTheName()
    var
        Rec: Record "ALT Universal";
    begin
        // AL's default caption is the object name, so a table declaring no Caption
        // answers with its name.
        Assert.AreEqual(
            'ALT Universal',
            Rec.TableCaption(),
            'TableCaption() must fall back to the object name when no Caption is declared');
    end;

    [Test]
    procedure RecordRef_Caption_DeclaredCaption_ReturnsTheCaption()
    var
        Rec: Record "ALT Captioned";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Assert.AreEqual(
            'Captioned Fixture Table',
            RecRef.Caption(),
            'RecordRef.Caption() must return the table''s declared Caption');
    end;

    [Test]
    procedure RecordRef_Name_DeclaredCaption_StillReturnsTheName()
    var
        Rec: Record "ALT Captioned";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Assert.AreEqual(
            'ALT Captioned',
            RecRef.Name(),
            'RecordRef.Name() must return the object name, not the declared Caption');
    end;
}
