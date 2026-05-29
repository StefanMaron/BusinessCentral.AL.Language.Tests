codeunit 60031 "ALT Event Mutation Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"ALT Event Publisher", 'OnBeforeAction', '', false, false)]
    local procedure OnBeforeActionMutateHandled(EntryNo: Integer; var Handled: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if (Control.GetScenario() = 'CODEUNIT-HANDLED') and (EntryNo = 7001) then
            Handled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnBeforeValidateEvent', 'Watched Field', false, false)]
    local procedure OnBeforeValidateMutate(var Rec: Record "ALT Triggered"; var xRec: Record "ALT Triggered"; CurrFieldNo: Integer)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        case Control.GetScenario() of
            'BEFORE-VALIDATE-REC':
                Rec.Name := 'BeforeValidateMutation';
            'BEFORE-VALIDATE-XREC':
                xRec."Watched Field" := 'XREC-BEFORE-VALIDATE';
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnAfterValidateEvent', 'Watched Field', false, false)]
    local procedure OnAfterValidateMutate(var Rec: Record "ALT Triggered"; var xRec: Record "ALT Triggered"; CurrFieldNo: Integer)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if Control.GetScenario() = 'AFTER-VALIDATE-REC' then
            Rec.Name := 'AfterValidateMutation';
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsertMutate(var Rec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if Control.GetScenario() = 'BEFORE-INSERT-REC' then
            Rec.Name := 'BeforeInsertMutation';
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsertMutate(var Rec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if Control.GetScenario() = 'AFTER-INSERT-REC' then
            Rec.Name := 'AfterInsertMutation';
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyMutate(var Rec: Record "ALT Triggered"; var xRec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        case Control.GetScenario() of
            'BEFORE-MODIFY-REC':
                Rec.Name := 'BeforeModifyMutation';
            'BEFORE-MODIFY-XREC':
                begin
                    xRec.Value := 4242;
                    xRec."Watched Field" := 'XREC-BEFORE-MODIFY';
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyMutate(var Rec: Record "ALT Triggered"; var xRec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if Control.GetScenario() = 'AFTER-MODIFY-REC' then
            Rec.Name := 'AfterModifyMutation';
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteMutate(var Rec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        case Control.GetScenario() of
            'BEFORE-DELETE-REC':
                begin
                    Rec.Value := 5151;
                    Rec."Watched Field" := 'BeforeDeleteMutation';
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteMutate(var Rec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if Control.GetScenario() = 'AFTER-DELETE-REC' then
            Rec.Value := 5252;
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnBeforeRenameEvent', '', false, false)]
    local procedure OnBeforeRenameMutate(var Rec: Record "ALT Triggered"; var xRec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        case Control.GetScenario() of
            'BEFORE-RENAME-REC':
                Rec.Name := 'BeforeRenameMutation';
            'BEFORE-RENAME-XREC':
                xRec.Value := 6262;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"ALT Triggered", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRenameMutate(var Rec: Record "ALT Triggered"; var xRec: Record "ALT Triggered"; RunTrigger: Boolean)
    var
        Control: Codeunit "ALT Event Mutation Control";
    begin
        if Control.GetScenario() = 'AFTER-RENAME-REC' then
            Rec.Name := 'AfterRenameMutation';
    end;
}
