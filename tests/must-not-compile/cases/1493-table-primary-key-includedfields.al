// @expect AL0690 | The primary key 'PK' on table 'MNC BS Included' (the first one in the key list) must not have the IncludedFields property set.
// @expect AL0687 | The key 'K2' on table 'MNC BS Included' cannot contain the fields defined for the primary key in the IncludeFields property.
// Corpus issue #668 item 82: IncludedFields on the primary key, and a secondary key whose IncludedFields names a primary-key field.
table 51493 "MNC BS Included"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; A; Integer) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; IncludedFields = A; }
        key(K2; A) { IncludedFields = Id; }
    }
}
