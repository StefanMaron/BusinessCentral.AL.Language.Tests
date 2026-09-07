table 60631 "ALT Page Evt Row"
{
    // Fixture for TestPageTriggerEvents.al — the source table of page 60632
    // "ALT Page Evt Rows", whose platform trigger events that suite pins.
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            DataClassification = CustomerContent;
        }
        field(10; "Value"; Text[50])
        {
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }
}
