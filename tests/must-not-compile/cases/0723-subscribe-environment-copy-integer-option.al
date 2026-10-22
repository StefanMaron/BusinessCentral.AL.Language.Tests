// @expect AL0284 | The type of the parameter 'SourceEnvironmentType' on the event subscriber 'Copy' does not match the expected type 'Option'.
// @expect AL0284 | The type of the parameter 'DestinationEnvironmentType' on the event subscriber 'Copy' does not match the expected type 'Option'.
// A subscriber to Environment Triggers.OnAfterCopyEnvironmentPerDatabase declares the environment type as Integer instead of an Option.
codeunit 50000 "MNC Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Environment Triggers", 'OnAfterCopyEnvironmentPerDatabase', '', false, false)]
    local procedure Copy(SourceEnvironmentType: Integer; SourceEnvironmentName: Text; DestinationEnvironmentType: Integer; DestinationEnvironmentName: Text)
    begin
    end;
}
