/// <summary>
/// Publisher table for the cross-app subscriber mutation test (corpus issue 15). It lives in
/// this dependency app; the subscriber that mutates it lives in the AL Language Coverage Tests
/// app, which depends on this one.
/// </summary>
table 61090 "ALT XApp Mut Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Trigger Field"; Code[20]) { }
        field(3; "Target Field"; Code[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
