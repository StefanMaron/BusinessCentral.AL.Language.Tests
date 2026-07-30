// Support table for TestInterfaceCodeunitStateField.al — an instance var-record field
// owned by "Interface Impl Vendor".

table 60369 "Interface State Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
