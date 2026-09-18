/// <summary>
/// Helper codeunit for TestRecordTruncateTryScope.al.
///
/// Its only job is to perform the Truncate() one call frame BELOW the [TryFunction] that
/// calls it. BC's NavMethodScope constructor ORs IsInTryScope in from the parent scope, so
/// this frame is inside the try scope only by INHERITANCE — it is not itself a try function.
/// A runner that set IsInTryScope on a literal try frame alone, and did not inherit it, would
/// let the Truncate() here through, which is the distinction the paired tests measure.
/// </summary>
codeunit 60924 "ALT Truncate Try Helper"
{
    procedure TruncateUniversal()
    var
        Universal: Record "ALT Universal";
    begin
        Universal.Truncate();
    end;
}
