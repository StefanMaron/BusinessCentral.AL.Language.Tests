// Batch 6, md:348: the namespaced object read by W6AllObjNamespace.al (a file with a namespace cannot name AllObj, so the test lives in a second file).

namespace W6Probe.Names;

table 67323 "W6 NS Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
