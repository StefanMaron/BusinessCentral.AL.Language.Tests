/// <summary>
/// The source table for "CFSF Header"'s FlowFields. It carries an ordinary link field
/// ("Doc No.") and a Guid link field ("Header Sys Id"), so the same set of rows can be
/// reached both by an ordinary where-arm and by one that reads the header's SystemId.
///
/// It declares no system fields of its own — every BC table has SystemId, SystemCreatedAt,
/// SystemCreatedBy, SystemModifiedAt and SystemModifiedBy whether it names them or not, and
/// that is exactly what the FlowFields on the header aggregate.
/// </summary>
table 60817 "CFSF Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Doc No."; Code[20]) { }
        field(3; "Header Sys Id"; Guid) { }
        field(4; Amount; Decimal) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
