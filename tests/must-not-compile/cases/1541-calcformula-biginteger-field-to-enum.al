// @expect AL0204 | Field type MNC BU E1541 is not convertible to field type BigInteger.
// @until 28
// @max-al 17
// A FlowField whose CalcFormula filters an Enum field by a BigInteger field (where(En = field(Big))), corpus issue 672,
// item 38. AL 18 and later warn (AL0663) and compile; BC 29 then fails at run time (DB:TypeMisMatch), see
// tests/al-language/types/lt-bu-property-conversions.
enum 51541 "MNC BU E1541"
{
    value(0; A) { }
}

table 51541 "MNC BU T1541"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; En; Enum "MNC BU E1541") { }
        field(4; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("MNC BU T1541" where(En = field(Big)));
        }
    }
}
