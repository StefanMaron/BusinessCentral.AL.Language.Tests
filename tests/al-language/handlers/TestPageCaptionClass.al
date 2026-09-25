// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
//                    https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-captionclass-property
// Scope: in-scope
// Fixtures used: TPCC Row (60981), TPCC Card (60981)
//
// TestPage.<field>.Caption() on a control that declares CaptionClass returns the CaptionClass
// expression as the caption-class resolver translates it -- not the control's source expression,
// not the source field's Caption, and not the control's own declared Caption. Area '3' returns the
// text after the first comma; an expression no resolver claims comes back unchanged. The expression
// is evaluated from page state, so a CaptionClass built from a page global reflects the value
// OnOpenPage gave it. Base Application matrix pages (CaptionClass = '3,' + MATRIX_ColumnCaption[N])
// depend on exactly this.

codeunit 60930 "TPCC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPCC Row";
    begin
        Row.DeleteAll();
    end;

    local procedure OpenCard(var Card: TestPage "TPCC Card")
    var
        Row: Record "TPCC Row";
    begin
        Row."No." := 'ROW1';
        Row.Insert();
        Card.OpenView();
    end;

    [Test]
    procedure TestPageField_Caption_CaptionClassFromPageGlobal_ReturnsResolvedText()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Sep 2026', Card.Column1.Caption(), 'Column1 caption from CaptionClass ''3,'' + ColumnCaption[1]');
        Assert.AreEqual('Oct 2026', Card.Column2.Caption(), 'Column2 caption from CaptionClass ''3,'' + ColumnCaption[2]');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_ConstantCaptionClass_WinsOverFieldCaption()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Fixed Text', Card.ConstantClass.Caption(), 'CaptionClass ''3,Fixed Text'' on a Rec-bound control');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_NoCaptionClass_ReturnsFieldCaption()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Quantity Field Caption', Card.NoClass.Caption(), 'a control without CaptionClass');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_CaptionClass_WinsOverDeclaredCaption()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('Class Caption', Card.CaptionAndClass.Caption(), 'a control declaring both Caption and CaptionClass');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_UnresolvedCaptionClass_ReturnsExpressionUnchanged()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        Assert.AreEqual('ZZ,Unknown Area', Card.UnknownArea.Caption(), 'a CaptionClass area no resolver claims');
        Assert.AreEqual('No Comma Here', Card.NoComma.Caption(), 'a CaptionClass with no area at all');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Caption_CaptionClass_IsNotTheSourceExpression()
    var
        Card: TestPage "TPCC Card";
    begin
        Initialize();
        OpenCard(Card);
        asserterror Assert.AreEqual('CellData[1]', Card.Column1.Caption(), 'source expression');
        Assert.ExpectedError('Sep 2026');
        Card.Close();
    end;
}
