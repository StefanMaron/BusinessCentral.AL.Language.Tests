// @expect AL0843 | The property 'OptionMembers' can only be used if the field's type is 'Option'.
// OptionMembers on an Integer field.
table 50127 "MNC T311"
{
    fields { field(1; Id; Integer) { OptionMembers = A, B; } }
    keys { key(PK; Id) { Clustered = true; } }
}
