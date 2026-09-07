/// <summary>
/// The PARENT side of the tableextension-CalcFormula pair, declared with no FlowField and no
/// FlowFilter of its own beyond the one control below. Everything the suite measures is added
/// to it by "TXC Cust Stats Ext", so a formula that resolves here is resolving a field the
/// EXTENSION contributed rather than one the table declares.
///
/// "Base Date Filter" is the deliberate exception: it is the control for the parent side, a
/// FlowFilter the BASE table declares, so "TXC Sales Base Filter" can run the same formula
/// shape against a non-extension flow filter.
/// </summary>
table 60809 "TXC Parent"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }

        /// Control: a FlowFilter the base table owns, paired with the extension-added
        /// "TXC Date Filter" so the two shapes differ only in who declared the filter.
        field(2; "Base Date Filter"; Date)
        {
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
