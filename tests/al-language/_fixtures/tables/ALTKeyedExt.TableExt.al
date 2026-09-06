// ALT Keyed is the shared fixture for key and sort-order tests. This extension pins the
// half a tableextension is usually assumed to have but nothing here proved: a
// tableextension adds KEYS and field PROPERTIES, not just columns.
//
//   * "Ext Rank" carries an InitValue, so Init() has something to write that is neither
//     the type default nor whatever the caller left in the field.
//   * "Ext Tag" deliberately carries no InitValue — it is the control that shows Init()
//     applies the declared value rather than stamping every extension field.
//   * key(ExtRank) is built only from an extension field.
//   * key(ExtMixed) mixes a base-table field with an extension field, which is the shape
//     a real per-tenant extension declares when it wants to sort inside an existing
//     status grouping.
tableextension 60330 "ALT Keyed Ext" extends "ALT Keyed"
{
    fields
    {
        field(60340; "Ext Rank"; Integer)
        {
            DataClassification = SystemMetadata;
            InitValue = 7;
        }
        field(60341; "Ext Tag"; Code[20])
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(ExtRank; "Ext Rank")
        {
        }
        key(ExtMixed; "Status", "Ext Rank")
        {
        }
    }
}
