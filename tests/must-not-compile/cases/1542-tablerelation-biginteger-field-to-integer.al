// @expect AL0204 | Field type Integer is not convertible to field type BigInteger.
// @until 28
// @max-al 17
// A TableRelation whose where clause filters an Integer field by a BigInteger field, corpus issue 672, item 38. AL 18 and
// later warn (AL0662) and compile, see tests/al-language/types/lt-bu-property-conversions.
table 51542 "MNC BU T1542"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; RelId; Integer) { TableRelation = "MNC BU T1542".Id where(Id = field(Big)); }
    }
}
