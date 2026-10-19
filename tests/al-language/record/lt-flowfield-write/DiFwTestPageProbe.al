// Corpus issue #665 item 12: TestPage SetValue on a page field bound to a FlowField. NOT a test: handlers/N582TestPageEdges.al records that
// SetValue on a FlowField page field crashes the service tier (NullReferenceException that no TryFunction catches) on the Linux container.
// The procedures below have no [Test] attribute, so CI never runs them; they wait for the Windows check (windows-queue.md, writer DI).
// Questions: does SetValue raise a catchable error (text, code) or crash, with the page field Editable (default) and Editable = false; does
// the session survive; does the source table (LT DI FW Child) change.

page 86265 "LT DI FW Parent Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT DI FW Parent";

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { }
            field(Name; Rec.Name) { }
            field("Has Children"; Rec."Has Children") { }
            field("First Child Code"; Rec."First Child Code") { Editable = false; }
            field("Child Amount"; Rec."Child Amount") { }
        }
    }
}

codeunit 86266 "LT DI FW TestPage Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    procedure DI_SetValueFlowFieldEditable()
    var
        Parent: Record "LT DI FW Parent";
        Card: TestPage "LT DI FW Parent Card";
    begin
        Parent.DeleteAll(false);
        Parent.Init();
        Parent."No." := 1;
        Parent.Insert(false);
        Card.OpenEdit();
        Card.GoToRecord(Parent);
        if TrySetValue(Card, false) then
            Error('PROBE: SetValue on an editable FlowField field gave no error')
        else
            Error('PROBE: %1|%2', GetLastErrorText(), GetLastErrorCode());
    end;

    procedure DI_SetValueFlowFieldNotEditable()
    var
        Parent: Record "LT DI FW Parent";
        Card: TestPage "LT DI FW Parent Card";
    begin
        Parent.DeleteAll(false);
        Parent.Init();
        Parent."No." := 1;
        Parent.Insert(false);
        Card.OpenEdit();
        Card.GoToRecord(Parent);
        if TrySetValue(Card, true) then
            Error('PROBE: SetValue on a not-editable FlowField field gave no error')
        else
            Error('PROBE: %1|%2', GetLastErrorText(), GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TrySetValue(var Card: TestPage "LT DI FW Parent Card"; NotEditable: Boolean)
    begin
        if NotEditable then
            Card."First Child Code".SetValue('ZZ')
        else
            Card."Has Children".SetValue(true);
    end;
}
