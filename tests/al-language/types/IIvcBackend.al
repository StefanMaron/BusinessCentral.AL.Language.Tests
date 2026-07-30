// Support interface for TestInterfaceVarCodeunitOut.al.
//
/// <summary>
/// Mirrors an ISV renderer shape: an interface whose only output travels through a
/// by-var Codeunit parameter, implemented by an enum value.
/// </summary>
interface "IIvc Backend"
{
    /// <summary>Fills <paramref name="Result"/>. Returns nothing by value — the by-var
    /// codeunit IS the result channel.</summary>
    procedure Produce(var Result: Codeunit "Temp Blob"; Payload: Text)
}
