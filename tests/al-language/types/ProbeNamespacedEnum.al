namespace Probe.NsEnum.Sub;

enum 69457 "Probe Ns Kind"
{
    Extensible = true;

    value(0; Zero) { }
    value(3; Three) { Caption = 'Three Cap'; }
}

table 69458 "Probe Ns Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "Probe Ns Kind") { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
