// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-extension-object
// Scope: in-scope
// Fixtures used: PCX Row (60520), PCX List (60521), PCX Row Ext (60522), PCX List Ext (60523)
//
// Pins what "Page Control Field" (2000000192) answers for a page that a PAGEEXTENSION adds a
// control to. TestPageControlFieldControlTree (codeunit 60426) pins the control tree of a
// single page object; every control it asserts is declared by the page itself, so a provider
// that reads only the base page's own definition passes it unchanged.
//
// That is the gap this file closes, and it is not hypothetical: an implementation whose only
// source is the base page's definition answers the extension's control with NO ROW AT ALL —
// a silently short result set rather than an error, which a test asserting a control is
// absent would pass just as happily as a correct one. So the first test below asserts the
// row EXISTS and resolves, and the second asserts the merged set is exactly the two controls
// rather than only checking that the added one is present.
//
// The added control is bound to a field contributed by a TABLEEXTENSION, so answering it
// correctly requires resolving the binding against the extended table rather than against
// the base table alone.
//
// Fixtures are private to this file rather than extending "ALT Control Tree Page": adding a
// pageextension to a shared fixture page would change what every other test reading that
// page observes.

codeunit 60524 "Test Page Control Fld PageExt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure Record_PageControlField_PageExtensionAddedControl_IsARow()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] "PCX Note" is declared by pageextension "PCX List Ext", never by the base
        // page, and is bound to a field contributed by tableextension "PCX Row Ext".
        PageControlField.SetRange(PageNo, Page::"PCX List");
        PageControlField.SetRange(ControlName, 'PCX Note');

        // [THEN] the control a pageextension adds is a row on the BASE page's id.
        Assert.IsTrue(PageControlField.FindFirst(), 'Page Control Field has no row for "PCX Note", the control added by pageextension "PCX List Ext".');

        // [THEN] and it resolves to the real source table/field rather than a blank row —
        // field 50 comes from the tableextension, so the binding was resolved against the
        // EXTENDED table.
        Assert.AreEqual(Database::"PCX Row", PageControlField.TableNo, 'Unexpected TableNo for "PCX Note".');
        Assert.AreEqual(50, PageControlField.FieldNo, 'Unexpected FieldNo for "PCX Note" (expected "PCX Note", id 50, contributed by the tableextension).');

        // [THEN] SourceExpression is the source FIELD's name, the same rule a control
        // declared by the base page follows — the extension does not change it.
        Assert.AreEqual('PCX Note', PageControlField.SourceExpression, 'SourceExpression for a pageextension-added, table-bound control must be the source field name.');
    end;

    [Test]
    procedure Record_PageControlField_PageExtensionControls_AreMergedWithTheBasePages()
    var
        PageControlField: Record "Page Control Field";
        SeenBase: Boolean;
        SeenAdded: Boolean;
    begin
        // [GIVEN] the base page declares exactly one field control and the pageextension
        // adds exactly one more.
        PageControlField.SetRange(PageNo, Page::"PCX List");

        // [THEN] the table reports the MERGED set: both controls, under the base page's id.
        // Counting is what catches an implementation that answers the extension's control
        // while dropping the base page's, or vice versa.
        Assert.AreEqual(2, PageControlField.Count(), 'Page Control Field must report both the base page''s control and the one the pageextension adds.');

        PageControlField.FindSet();
        repeat
            case PageControlField.ControlName of
                'PCX No.':
                    SeenBase := true;
                'PCX Note':
                    SeenAdded := true;
            end;
        until PageControlField.Next() = 0;

        Assert.IsTrue(SeenBase, 'The base page''s own control "PCX No." is missing from the merged set.');
        Assert.IsTrue(SeenAdded, 'The pageextension''s control "PCX Note" is missing from the merged set.');
    end;

    [Test]
    procedure Record_PageControlField_PageExtensionControl_IsNotARowOnTheExtensionsOwnId()
    var
        PageControlField: Record "Page Control Field";
    begin
        // [GIVEN] the pageextension is object 60523 and the page it extends is 60521.
        PageControlField.SetRange(PageNo, 60523);

        // [THEN] the merged control belongs to the BASE page, so nothing is reported under
        // the pageextension's own object id. A provider that keyed rows on the declaring
        // object would put "PCX Note" here instead, and both of the tests above would still
        // pass if they only checked the base page for its presence.
        Assert.AreEqual(0, PageControlField.Count(), 'Page Control Field must report no rows under a pageextension''s own object id; its controls belong to the page it extends.');
    end;

    // Writer QZ: movefirst / movelast / moveafter / movebefore in a page extension (fixtures in QzPageExtMoves.al).
    [Test]
    procedure QZ_PageExtMoves_PageOpensAndControlsWork()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT QZ Move Row";
        Card: TestPage "LT QZ Move Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.A := 'a';
        Row.B := 'b';
        Row.C := 'c';
        Row.D := 'd';
        Row.E := 'e';
        Row.Insert();
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Observer.Observe('values', Card.IdCtl.Value() + '|' + Card.ACtl.Value() + '|' + Card.BCtl.Value() + '|' + Card.CCtl.Value() + '|' + Card.DCtl.Value() + '|' + Card.ECtl.Value());
        Card.ACtl.SetValue('a2');
        Card.CCtl.SetValue('c2');
        Card.BCtl.SetValue('b2');
        Card.ECtl.SetValue('e2');
        Card.Close();
        Row.Get(1);
        Observer.Observe('stored', Row.A + '|' + Row.B + '|' + Row.C + '|' + Row.D + '|' + Row.E);
        Observer.Expect('values', '1|a|b|c|d|e');
        Observer.Expect('stored', 'a2|b2|c2|d|e2');
        Observer.Verify();
    end;

    [Test]
    procedure QZ_PageExtMoves_PageControlFieldRows()
    var
        Observer: Codeunit "Probe Observer";
        PageControlField: Record "Page Control Field";
        RecRef: RecordRef;
        Columns: Text;
        Rows: Text;
        Name: Text;
        Index: Integer;
    begin
        RecRef.Open(Database::"Page Control Field");
        for Index := 1 to RecRef.FieldCount() do
            Columns += Format(RecRef.FieldIndex(Index).Number()) + '=' + RecRef.FieldIndex(Index).Name() + ',';
        Observer.Observe('columns', Columns);
        // Sequence of each control (the rows come in ControlId order, an id the compiler derives, so they are read by name).
        PageControlField.SetRange(PageNo, Page::"LT QZ Move Card");
        foreach Name in 'IdCtl,ACtl,BCtl,CCtl,DCtl,ECtl'.Split(',') do begin
            PageControlField.SetRange(ControlName, Name);
            if PageControlField.FindFirst() then
                Rows += Name + '=' + Format(PageControlField.Sequence) + ';'
            else
                Rows += Name + '=no row;';
        end;
        Observer.Observe('rows', Rows);
        Observer.Expect('columns', '1=PageNo,2=ControlId,3=ControlName,4=TableNo,5=FieldNo,6=Enabled,7=Editable,8=Visible,9=SourceExpression,10=OptionString,11=Sequence,');
        Observer.Expect('rows', 'IdCtl=1;ACtl=5;BCtl=0;CCtl=2;DCtl=4;ECtl=3;');
        Observer.Verify();
    end;
}
