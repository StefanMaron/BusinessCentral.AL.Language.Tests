// @expect AL0450 | Field 'MNC BO Old' is removed and cannot be used in an active key.
// @expect AL0450 | Field 'Old' is removed and cannot be used in an active key.
// A field with ObsoleteState = Removed in an active key: in a table extension (key of the extension) and in a table. Corpus issue 664
// item 98 (microsoft/AL#6680). Writer BO. (2 diagnostics)
tableextension 51423 "MNC BO 1417" extends Customer
{
    fields { field(51423; "MNC BO Old"; Integer) { ObsoleteState = Removed; ObsoleteReason = 'gone'; } }
    keys { key(MncBoKey; "MNC BO Old") { } }
}

table 51424 "MNC BO 1417 T"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Old; Integer) { ObsoleteState = Removed; ObsoleteReason = 'gone'; }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
        key(K2; Old) { }
    }
}
