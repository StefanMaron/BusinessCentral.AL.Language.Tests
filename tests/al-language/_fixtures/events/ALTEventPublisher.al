codeunit 60014 "ALT Event Publisher"
{
    // Integration event - can be subscribed externally
    [IntegrationEvent(false, false)]
    procedure OnBeforeAction(EntryNo: Integer; var Handled: Boolean)
    begin
    end;

    // Business event
    [BusinessEvent(false)]
    procedure OnAfterAction(EntryNo: Integer; Result: Integer)
    begin
    end;

    // Internal event - only subscribable within the same app
    [InternalEvent(false)]
    procedure OnInternalStep(Step: Integer)
    begin
    end;

    procedure TriggerBefore(EntryNo: Integer)
    var
        Handled: Boolean;
    begin
        OnBeforeAction(EntryNo, Handled);
    end;

    procedure TriggerBeforeAndReturnHandled(EntryNo: Integer): Boolean
    var
        Handled: Boolean;
    begin
        OnBeforeAction(EntryNo, Handled);
        exit(Handled);
    end;

    procedure TriggerAfter(EntryNo: Integer; Result: Integer)
    begin
        OnAfterAction(EntryNo, Result);
    end;

    procedure TriggerInternal(Step: Integer)
    begin
        OnInternalStep(Step);
    end;
}
