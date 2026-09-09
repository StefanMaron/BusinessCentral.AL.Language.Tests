// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-object
// Scope: in-scope
// Fixtures used: ALT Control Tree Page (60427), ALT Universal (60000)
//
// Pins what the "Page Control Field" (2000000192) virtual table answers for a page whose
// controls are NOT all plain top-level Rec.-bound fields. TestPageControlFieldVirtualTable
// (codeunit 60921) already pins the plain case against "ALT List Page"; every control there
// is bound to a Rec field and sits one level below the repeater, so a provider that walks
// only the top level, or that drops any control it cannot bind to a table field, passes it
// unchanged. The three properties below are the ones such a provider gets wrong:
//
//   * a control nested three group levels deep is still a row;
//   * a control bound to a page VARIABLE is still a row, and its SourceExpression is the
//     variable name — the table does not restrict itself to table-bound controls;
//   * SourceExpression for a table-bound control is the source FIELD NAME, not the AL
//     binding text that produced it, and OptionString carries the source field's option
//     members.
//
// Enabled/Editable/Visible are TEXT columns carrying the resolved property expression, so
// they round-trip through Evaluate() rather than comparing to a Boolean directly.

codeunit 60426 "Test Page Control Field Tree"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageControlField_ControlNestedThreeGroupsDeep_IsARow()
    var
        PageControlField: Record "Page Control Field";
        IsVisible: Boolean;
    begin
        // [GIVEN] TreeDeepHidden sits inside group(Level3) inside group(Level2) inside
        // group(Level1) and declares Visible = false.
        PageControlField.SetRange(PageNo, Page::"ALT Control Tree Page");
        PageControlField.SetRange(ControlName, 'TreeDeepHidden');

        // [THEN] depth does not remove it from the table.
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for the depth-3 control "TreeDeepHidden".');

        // [THEN] and it resolves to the real source table/field rather than a blank row.
        Assert.AreEqual(Database::"ALT Universal", PageControlField.TableNo, 'Unexpected TableNo for "TreeDeepHidden".');
        Assert.AreEqual(18, PageControlField.FieldNo, 'Unexpected FieldNo for "TreeDeepHidden" (expected "Name Field", id 18).');

        Assert.IsTrue(Evaluate(IsVisible, PageControlField.Visible), 'Visible column is not an evaluable Boolean expression for "TreeDeepHidden".');
        Assert.IsFalse(IsVisible, '"TreeDeepHidden" declares Visible = false; the table must report that at depth 3 too.');
    end;

    [Test]
    procedure Record_PageControlField_TableBoundControl_SourceExpressionIsTheFieldName()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] "Entry No." is declared as `field("Entry No."; Rec."Entry No.")`.
        PageControlField.SetRange(PageNo, Page::"ALT Control Tree Page");
        PageControlField.SetRange(ControlName, 'Entry No.');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "Entry No.".');

        // [THEN] SourceExpression is the source field's NAME, not the AL binding text
        // `Rec."Entry No."` that produced it.
        Assert.AreEqual('Entry No.', PageControlField.SourceExpression, 'SourceExpression for a table-bound control must be the source field name.');
        Assert.AreEqual(Database::"ALT Universal", PageControlField.TableNo, 'Unexpected TableNo for "Entry No.".');
        Assert.AreEqual(1, PageControlField.FieldNo, 'Unexpected FieldNo for "Entry No.".');
    end;

    [Test]
    procedure Record_PageControlField_VariableBoundControl_IsARowNamingTheVariable()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] TreeLocalVar is declared as `field(TreeLocalVar; LocalTreeVar)` — bound to
        // a page variable, so there is no table field behind it.
        PageControlField.SetRange(PageNo, Page::"ALT Control Tree Page");
        PageControlField.SetRange(ControlName, 'TreeLocalVar');

        // [THEN] the control is still a row: the table lists every field control on the page,
        // not only the ones bound to a table field.
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for the variable-bound control "TreeLocalVar".');

        // [THEN] SourceExpression names the variable it is bound to.
        Assert.AreEqual('LocalTreeVar', PageControlField.SourceExpression, 'SourceExpression for a variable-bound control must be the variable name.');

        // [THEN] and it has no source field, while TableNo still reports the page's source table.
        Assert.AreEqual(0, PageControlField.FieldNo, 'A control bound to a page variable has no source field, so FieldNo must be 0.');
        Assert.AreEqual(Database::"ALT Universal", PageControlField.TableNo, 'TableNo is the PAGE''s source table and is stated even for a control with no source field.');
    end;

    [Test]
    procedure Record_PageControlField_OptionBoundControl_OptionStringIsTheFieldsMembers()
    var
        PageControlField: Record "Page Control Field";
        Members: List of [Text];
    begin
        // [GIVEN] TreeOption is bound to "Option Field", declared
        // `OptionMembers = " ",Draft,Active,Closed`.
        PageControlField.SetRange(PageNo, Page::"ALT Control Tree Page");
        PageControlField.SetRange(ControlName, 'TreeOption');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "TreeOption".');

        Assert.AreEqual(14, PageControlField.FieldNo, 'Unexpected FieldNo for "TreeOption" (expected "Option Field", id 14).');

        // [THEN] OptionString carries the source field's option members, not an empty
        // string. Split and asserted per member rather than as one literal, so the test
        // does not pin how the blank first member is spelled.
        Assert.AreNotEqual('', PageControlField.OptionString, 'OptionString must carry the source field''s option members for an Option-bound control.');
        Members := PageControlField.OptionString.Split(',');
        Assert.AreEqual(4, Members.Count(), 'OptionString must state four option members for "Option Field".');
        Assert.AreEqual('Draft', Members.Get(2), 'Unexpected second option member of "Option Field".');
        Assert.AreEqual('Active', Members.Get(3), 'Unexpected third option member of "Option Field".');
        Assert.AreEqual('Closed', Members.Get(4), 'Unexpected fourth option member of "Option Field".');
    end;

    [Test]
    procedure Record_PageControlField_TextBoundControl_OptionStringIsEmpty()
    var
        PageControlField: Record "Page Control Field";
    begin
        // Negative direction for the test above: OptionString is not filled unconditionally.
        // "TreeDeepEditable" is bound to "Description Field", a Text field.
        PageControlField.SetRange(PageNo, Page::"ALT Control Tree Page");
        PageControlField.SetRange(ControlName, 'TreeDeepEditable');
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for control "TreeDeepEditable".');

        Assert.AreEqual(17, PageControlField.FieldNo, 'Unexpected FieldNo for "TreeDeepEditable" (expected "Description Field", id 17).');
        Assert.AreEqual('', PageControlField.OptionString, 'OptionString must be empty for a control bound to a non-Option field.');
        Assert.AreEqual('Description Field', PageControlField.SourceExpression, 'SourceExpression for a table-bound control must be the source field name.');
    end;
}
