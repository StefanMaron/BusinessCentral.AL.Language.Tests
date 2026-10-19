// @expect AL0124 | The property 'Owner' cannot be used in this context.
// @expect AL0124 | The property 'Owner' cannot be used in this context.
// The Owner property on a Blob field and on an Integer field is not a field property. Corpus issue 664 item 96 (microsoft/AL#3537).
// Writer BO. (2 diagnostics)
table 51422 "MNC BO 1416"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; B; Blob) { Owner = 'Someone'; }
        field(3; N; Integer) { Owner = 'Someone'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
