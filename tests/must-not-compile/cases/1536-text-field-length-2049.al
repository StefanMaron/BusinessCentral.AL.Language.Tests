// @expect AL0154 | The maximum length for a field of type 'Text' is 2048
// A Text[2049] table field (corpus issue 672, item 43).
table 51536 "MNC BU T1536"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; T; Text[2049]) { }
    }
}
