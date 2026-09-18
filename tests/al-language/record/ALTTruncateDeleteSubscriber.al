/// <summary>
/// Subscriber-only codeunit for TestRecordTruncateEventAndFilterGuards.al.
///
/// Its ONLY purpose is to make "ALT Truncate Guard Row" a table with an
/// OnBeforeDeleteEvent subscription, which is the precondition
/// NavRecord.ValidateTruncateSupport tests through
/// NCLMetaTable.IsEventSubscribed(OnBeforeDeleteEvent, appGroup).
///
/// The body is deliberately EMPTY. The guard fires on the existence of a subscription, not
/// on anything the subscriber does, and an empty body keeps the test measuring exactly that
/// — a subscriber that raised an error would make a refused Truncate() and a fired trigger
/// indistinguishable in the assertion.
/// </summary>
codeunit 60517 "ALT Truncate Delete Sub"
{
    [EventSubscriber(ObjectType::Table, Database::"ALT Truncate Guard Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDeleteGuardRow(var Rec: Record "ALT Truncate Guard Row"; RunTrigger: Boolean)
    begin
    end;
}
