// @expect AL0288 | Parameter 'Plain' is only allowed to be 'var' if the publisher parameter is 'var'.
// A subscriber declares var on a parameter the publisher passes by value (corpus issue 669, item 15, the reverse direction).
// The other direction (publisher var, subscriber without var) compiles without a warning on BC 27, 28 and 29.
codeunit 50000 "MNC CK Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnH(var Handled: Boolean; Plain: Boolean)
    begin
    end;
}

codeunit 50001 "MNC CK Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC CK Pub", 'OnH', '', false, false)]
    local procedure S(var Plain: Boolean)
    begin
    end;
}
