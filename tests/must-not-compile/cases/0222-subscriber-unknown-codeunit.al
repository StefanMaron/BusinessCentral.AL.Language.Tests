// @expect AL0118 | The name '"MNC No Such Codeunit"' does not exist in the current context.
// An event subscriber names a publisher codeunit that does not exist.
codeunit 50027 "MNC C222"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC No Such Codeunit", 'OnX', '', false, false)]
    local procedure Handle()
    begin
    end;
}
