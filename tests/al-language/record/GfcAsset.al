// Rows resolve by ranging Scope/Name/StyleVariant while EXCLUDING rows whose
// owning-app GUID (SourceAppId) was never set.
table 60233 "GFC Asset"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Scope; Enum "GFC Scope") { }
        field(2; SourceAppId; Guid) { }
        field(3; Name; Code[50]) { }
        field(4; StyleVariant; Enum "GFC Style Variant") { }
        field(5; Payload; Text[30]) { }
    }

    keys
    {
        key(PK; Scope, SourceAppId, Name, StyleVariant) { Clustered = true; }
    }
}
