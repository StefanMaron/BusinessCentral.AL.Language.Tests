// @expect AL0204 | Field type Integer is not convertible to field type BigInteger.
// @until 28
// @max-al 17
// A FlowField whose CalcFormula filters an Integer field by a BigInteger field (where(Id = field(Big))), corpus issue 672,
// item 38. The AL 16 and 17 compilers (and the server compilers of BC 27.5 and 28.5, which reject the publish with this error)
// refuse it; AL 18 and later warn (AL0662) and compile, see tests/al-language/types/lt-bu-property-conversions.
table 51540 "MNC BU T1540"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("MNC BU T1540" where(Id = field(Big)));
        }
    }
}
