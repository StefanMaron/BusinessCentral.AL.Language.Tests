// @expect AL0154 | The maximum length for a field of type 'Code' is 2048
// A Code[2049] table field (corpus issue 672, item 43).
table 51535 "MNC BU T1535"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; C; Code[2049]) { }
    }
}
