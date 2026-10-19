// @expect AL0103 | Constant value '3000000000' is outside the range for an Integer
// InitValue of an Integer field with a value beyond the Integer range does not compile (corpus issue 672, item 38).
table 51735 "MNC CQ T1735"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Qty; Integer) { InitValue = 3000000000; }
    }
}
