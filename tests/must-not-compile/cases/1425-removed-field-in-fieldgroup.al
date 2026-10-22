// @expect AL0433 | Field 'Old' is removed. Reason: gone.
// A field with ObsoleteState = Removed kept in a fieldgroup (a Pending field there gives only warning AL0432, so it compiles). Corpus
// issue 664 item 108 (microsoft/AL#6540). Writer BO.
table 51432 "MNC BO 1425"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Old; Integer) { ObsoleteState = Removed; ObsoleteReason = 'gone'; }
        field(3; Pend; Integer) { ObsoleteState = Pending; ObsoleteReason = 'going'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
    fieldgroups { fieldgroup(DropDown; Id, Old, Pend) { } }
}
