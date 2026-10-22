// @expect AL0154 | The maximum length for a field of type 'Code' is 2048
// A Code table field may be at most Code[2048] (corpus issue 672, item 43).
table 51731 "MNC CQ T1731"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Long; Code[2049]) { }
    }
}
