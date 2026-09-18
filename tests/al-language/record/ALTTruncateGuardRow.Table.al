/// <summary>
/// Fixture for TestRecordTruncateEventAndFilterGuards.al — the table that carries an
/// OnBeforeDeleteEvent subscriber (codeunit 60517).
///
/// Deliberately minimal and NOT shared with any other suite: BC's ValidateTruncateSupport
/// runs seven guards in order and reports the FIRST that holds, so a fixture that also
/// tripped an earlier guard would make the delete-subscriber test pass for the wrong
/// reason. This table is normal (not temporary, not a system table), has no Media or
/// MediaSet field, and no FlowField — so guards 1, 2, 6 and 7 all pass and the subscriber
/// guard is the only one left that can fire.
/// </summary>
table 60515 "ALT Truncate Guard Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            DataClassification = CustomerContent;
        }
        field(2; "Amount Field"; Decimal)
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
