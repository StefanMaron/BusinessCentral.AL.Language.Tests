// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SessionInformation.Callstack read from the places session/TestSessionCallstackSourcesContracts.al does not cover: table triggers (OnInsert, OnModify, OnDelete, field OnValidate), subscribers of the database events OnBeforeInsert, OnBeforeModify, OnAfterModify, OnBeforeDelete, OnAfterDelete and of the field validate events, page field triggers (OnValidate, OnDrillDown, OnAssistEdit, OnLookup) and page triggers (OnNewRecord, OnAfterGetRecord, OnInsertRecord, OnModifyRecord, OnQueryClosePage, OnClosePage); the stack as text cut above the test runner frames
// BC versions: 29 (27 and 28 by CI)

table 74436 "LT P137 CS Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Val; Integer)
        {
            trigger OnValidate()
            var
                Ctl: Codeunit "LT P137 Ctl";
            begin
                Ctl.Add('field Val OnValidate: ' + Ctl.CutRunner(SessionInformation.Callstack));
            end;
        }
        field(3; Note; Text[30]) { }
        field(4; Data; Blob) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('table OnInsert: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    trigger OnModify()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('table OnModify: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    trigger OnDelete()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('table OnDelete: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 74438 "LT P137 CS Subs"
{
    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnBeforeInsertEvent', '', false, false)]
    local procedure BeforeInsert(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub BeforeInsert: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnBeforeModifyEvent', '', false, false)]
    local procedure BeforeModify(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub BeforeModify: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnAfterModifyEvent', '', false, false)]
    local procedure AfterModify(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub AfterModify: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure BeforeDelete(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub BeforeDelete: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnAfterDeleteEvent', '', false, false)]
    local procedure AfterDelete(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub AfterDelete: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnBeforeValidateEvent', 'Val', false, false)]
    local procedure BeforeValidate(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub BeforeValidate: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P137 CS Table", 'OnAfterValidateEvent', 'Val', false, false)]
    local procedure AfterValidate(var Rec: Record "LT P137 CS Table")
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('sub AfterValidate: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;
}

page 74439 "LT P137 CS Page"
{
    PageType = Card;
    SourceTable = "LT P137 CS Table";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id)
            {
                ApplicationArea = All;

                trigger OnAssistEdit()
                var
                    Ctl: Codeunit "LT P137 Ctl";
                begin
                    Ctl.Add('page field Id OnAssistEdit: ' + Ctl.CutRunner(SessionInformation.Callstack));
                end;
            }
            field(Val; Rec.Val)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Ctl: Codeunit "LT P137 Ctl";
                begin
                    Ctl.Add('page field Val OnValidate: ' + Ctl.CutRunner(SessionInformation.Callstack));
                end;

                trigger OnDrillDown()
                var
                    Ctl: Codeunit "LT P137 Ctl";
                begin
                    Ctl.Add('page field Val OnDrillDown: ' + Ctl.CutRunner(SessionInformation.Callstack));
                end;
            }
            field(Note; Rec.Note)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Ctl: Codeunit "LT P137 Ctl";
                begin
                    Ctl.Add('page field Note OnLookup: ' + Ctl.CutRunner(SessionInformation.Callstack));
                    exit(true);
                end;
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('page OnNewRecord: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    trigger OnAfterGetRecord()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('page OnAfterGetRecord: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('page OnInsertRecord: ' + Ctl.CutRunner(SessionInformation.Callstack));
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('page OnModifyRecord: ' + Ctl.CutRunner(SessionInformation.Callstack));
        exit(true);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('page OnQueryClosePage: ' + Ctl.CutRunner(SessionInformation.Callstack));
        exit(true);
    end;

    trigger OnClosePage()
    var
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Ctl.Add('page OnClosePage: ' + Ctl.CutRunner(SessionInformation.Callstack));
    end;
}

codeunit 74442 "LT P137 Callstack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Clean()
    var
        Row: Record "LT P137 CS Table";
        Ctl: Codeunit "LT P137 Ctl";
    begin
        Row.DeleteAll(false);
        Ctl.Take();
    end;

    [Test]
    procedure P137_Callstack_TableTriggersAndEvents()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Row: Record "LT P137 CS Table";
    begin
        Clean();
        Row.Id := 1;
        Row.Insert(true);
        Observer.Observe('insert', Ctl.Take());
        Row.Validate(Val, 5);
        Observer.Observe('validate', Ctl.Take());
        Row.Modify(true);
        Observer.Observe('modify', Ctl.Take());
        Row.Delete(true);
        Observer.Observe('delete', Ctl.Take());
        Observer.Expect('insert', 'sub BeforeInsert: "LT P137 CS Subs"(CodeUnit 74438).BeforeInsert line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 8 - AL Language Coverage Tests by AL Language version x\;table OnInsert: "LT P137 CS Table"(Table 74436).OnInsert(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 8 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('validate', 'sub BeforeValidate: "LT P137 CS Subs"(CodeUnit 74438).BeforeValidate line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 10 - AL Language Coverage Tests by AL Language version x\;field Val OnValidate: "LT P137 CS Table"(Table 74436)."Val - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 10 - AL Language Coverage Tests by AL Language version x\;sub AfterValidate: "LT P137 CS Subs"(CodeUnit 74438).AfterValidate line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 10 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('modify', 'sub BeforeModify: "LT P137 CS Subs"(CodeUnit 74438).BeforeModify line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 12 - AL Language Coverage Tests by AL Language version x\;table OnModify: "LT P137 CS Table"(Table 74436).OnModify(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 12 - AL Language Coverage Tests by AL Language version x\;sub AfterModify: "LT P137 CS Subs"(CodeUnit 74438).AfterModify line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 12 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('delete', 'sub BeforeDelete: "LT P137 CS Subs"(CodeUnit 74438).BeforeDelete line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 14 - AL Language Coverage Tests by AL Language version x\;table OnDelete: "LT P137 CS Table"(Table 74436).OnDelete(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 14 - AL Language Coverage Tests by AL Language version x\;sub AfterDelete: "LT P137 CS Subs"(CodeUnit 74438).AfterDelete line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableTriggersAndEvents line 14 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Verify();
    end;





    [Test]
    procedure P137_Callstack_TableWithoutTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Row: Record "LT P137 CS Table";
    begin
        Clean();
        Row.Id := 2;
        Row.Insert(false);
        Observer.Observe('insert_no_trigger', Ctl.Take());
        Row.Val := 3;
        Row.Modify(false);
        Observer.Observe('modify_no_trigger', Ctl.Take());
        Row.Delete(false);
        Observer.Observe('delete_no_trigger', Ctl.Take());
        Observer.Expect('insert_no_trigger', 'sub BeforeInsert: "LT P137 CS Subs"(CodeUnit 74438).BeforeInsert line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableWithoutTriggers line 8 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('modify_no_trigger', 'sub BeforeModify: "LT P137 CS Subs"(CodeUnit 74438).BeforeModify line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableWithoutTriggers line 11 - AL Language Coverage Tests by AL Language version x\;sub AfterModify: "LT P137 CS Subs"(CodeUnit 74438).AfterModify line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableWithoutTriggers line 11 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('delete_no_trigger', 'sub BeforeDelete: "LT P137 CS Subs"(CodeUnit 74438).BeforeDelete line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableWithoutTriggers line 13 - AL Language Coverage Tests by AL Language version x\;sub AfterDelete: "LT P137 CS Subs"(CodeUnit 74438).AfterDelete line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_TableWithoutTriggers line 13 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Callstack_PageFieldAndPageTriggers_New()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Card: TestPage "LT P137 CS Page";
    begin
        Clean();
        Card.OpenNew();
        Observer.Observe('open_new', Ctl.Take());
        Card.Id.SetValue(7);
        Observer.Observe('set_id', Ctl.Take());
        Card.Val.SetValue(8);
        Observer.Observe('set_val', Ctl.Take());
        Card.Note.SetValue('n');
        Observer.Observe('set_note', Ctl.Take());
        Card.Val.Drilldown();
        Observer.Observe('drilldown', Ctl.Take());
        Card.Id.AssistEdit();
        Observer.Observe('assistedit', Ctl.Take());
        Card.Note.Lookup();
        Observer.Observe('lookup', Ctl.Take());
        Card.Close();
        Observer.Observe('close', Ctl.Take());
        Observer.Expect('open_new', 'sub OnOpenPageEvent: "LT P137 CS Page Subs"(CodeUnit 74443).OnOpenPageSub line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageFieldAndPageTriggers_New line 7 - AL Language Coverage Tests by AL Language version x\;page OnNewRecord: "LT P137 CS Page"(Page 74439).OnNewRecord(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageFieldAndPageTriggers_New line 7 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('set_id', '');
        Observer.Expect('set_note', '');
        Observer.Expect('drilldown', 'page field Val OnDrillDown: "LT P137 CS Page"(Page 74439)."Val - OnDrillDown"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageFieldAndPageTriggers_New line 15 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('assistedit', 'page field Id OnAssistEdit: "LT P137 CS Page"(Page 74439)."Id - OnAssistEdit"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageFieldAndPageTriggers_New line 17 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('lookup', 'page field Note OnLookup: "LT P137 CS Page"(Page 74439)."Note - OnLookup"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageFieldAndPageTriggers_New line 19 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Ignore('set_val'); // a dump or environment data: observed, not asserted
        Observer.Ignore('close'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;





    [Test]
    procedure P137_Callstack_PageTriggers_Existing()
    var
        Observer: Codeunit "Probe Observer";
        Ctl: Codeunit "LT P137 Ctl";
        Row: Record "LT P137 CS Table";
        Card: TestPage "LT P137 CS Page";
    begin
        Clean();
        Row.Id := 9;
        Row.Insert(false);
        Ctl.Take();
        Card.OpenEdit();
        Observer.Observe('open_edit', Ctl.Take());
        Card.Val.SetValue(4);
        Observer.Observe('set_val', Ctl.Take());
        Card.Close();
        Observer.Observe('close', Ctl.Take());
        Observer.Expect('open_edit', 'sub OnOpenPageEvent: "LT P137 CS Page Subs"(CodeUnit 74443).OnOpenPageSub line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 11 - AL Language Coverage Tests by AL Language version x\;page OnAfterGetRecord: "LT P137 CS Page"(Page 74439).OnAfterGetRecord(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 11 - AL Language Coverage Tests by AL Language version x\;sub OnAfterGetRecordEvent: "LT P137 CS Page Subs"(CodeUnit 74443).OnAfterGetRecordSub line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 11 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Expect('set_val', 'sub BeforeValidate: "LT P137 CS Subs"(CodeUnit 74438).BeforeValidate line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 13 - AL Language Coverage Tests by AL Language version x\;field Val OnValidate: "LT P137 CS Table"(Table 74436)."Val - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 13 - AL Language Coverage Tests by AL Language version x\;sub AfterValidate: "LT P137 CS Subs"(CodeUnit 74438).AfterValidate line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 13 - AL Language Coverage Tests by AL Language version x\;page field Val OnValidate: "LT P137 CS Page"(Page 74439)."Val - OnValidate"(Trigger) line 4 - AL Language Coverage Tests by AL Language version x\"LT P137 Callstack"(CodeUnit 74442).P137_Callstack_PageTriggers_Existing line 13 - AL Language Coverage Tests by AL Language version x\;');
        Observer.Ignore('close'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;




}
