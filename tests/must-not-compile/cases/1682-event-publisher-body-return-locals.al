// @expect AL0286 | The event 'WithBody' can't contain code.
// @expect AL0283 | The event 'WithReturn' must not have a return value.
// @expect AL0287 | The event 'WithLocal' can't contain local variables.
// @expect AL0287 | The event 'WithLabel' can't contain local variables.
// Event publisher rules (corpus issue 669, item 8): a publisher with a statement, a return value, a local variable, a local Label.
// Same codes on BC 27, 28 and 29. A page publisher event subscribed on a page without SourceTable compiles (no error).
codeunit 50000 "MNC CK Pub"
{
    [IntegrationEvent(false, false)]
    local procedure WithBody()
    begin
        Message('x');
    end;

    [IntegrationEvent(false, false)]
    local procedure WithReturn(): Integer
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure WithLocal()
    var
        I: Integer;
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure WithLabel()
    var
        L: Label 'abc';
    begin
    end;
}
