// Tests for the fixture in TestPageExtensionControlBinding_Page.al.
//
// CLAIM: a control declared by a PAGEEXTENSION is reachable through a TestPage and carries its
// value, whether it is bound to a variable the pageextension declares or to a field of the
// extended page's SourceTable.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4145, which reports
// NavTestFieldNotFoundException on the global-bound case. Nothing here predicts the runner's
// answer -- these arms record what BC does, which is the thing that was missing.

codeunit 60978 "PXC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "PXC Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row."Rec Text" := 'RECTEXT';
        Row.Insert();
    end;

    [Test]
    procedure PageExtControl_BoundToExtensionGlobal_IsFoundAndReadsItsValue()
    // The half AL Runner #4145 reports failing. OnOpenPage assigns the global, so a found
    // control must read the assigned value rather than a blank.
    var
        Card: TestPage "PXC Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey(1);
        Assert.AreEqual(
            'EXTGLOBAL', Card.ExtGlobalField.Value(),
            'A pageextension control bound to an extension global must read the value its OnOpenPage assigned.');
        Card.Close();
    end;

    [Test]
    procedure PageExtControl_BoundToRecField_IsFoundAndReadsItsValue()
    // The discriminating half. Same pageextension, same layout block, different binding.
    //
    // Read together with the arm above: both passing means extension controls reach the page
    // metadata and any global-bound failure is about source expressions; both failing means
    // the metadata does not carry extension controls at all. Neither arm alone says which.
    var
        Card: TestPage "PXC Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey(1);
        Assert.AreEqual(
            'RECTEXT', Card.ExtRecField.Value(),
            'A pageextension control bound to a SourceTable field must read that field''s value.');
        Card.Close();
    end;

    [Test]
    procedure PageExtControl_BaseControl_StillReadable()
    // The control. If the base page's own control stopped being readable, the two arms above
    // would fail for a reason that has nothing to do with pageextensions.
    var
        Card: TestPage "PXC Card";
    begin
        Initialize();

        Card.OpenEdit();
        Card.GoToKey(1);
        Assert.AreEqual(
            '1', Card."Entry No.".Value(),
            'The base page''s own control must still be readable alongside the extension''s.');
        Card.Close();
    end;
}
