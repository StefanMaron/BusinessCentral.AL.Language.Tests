// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-data-type
// Scope: in-scope
// Fixtures used: self-contained (table 74200)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

table 74200 "LT StT Rec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
        field(3; Pic; Media) { }
        field(4; Pics; MediaSet) { }
        field(5; Name; Text[50]) { }
        field(6; Pic2; Media) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
