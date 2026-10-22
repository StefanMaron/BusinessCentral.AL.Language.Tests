// @expect AL0427 | Field Looked cannot be converted to type BigInteger.
// A lookup FlowField of type Enum over a BigInteger field does not compile (corpus issue 672, item 38). An Integer lookup FlowField over
// a BigInteger field compiles with warning AL0662: tests/al-language/misc/lt-cq-odd-leads/CqOddLeadObjects.al.
enum 51734 "MNC CQ E1734"
{
    Extensible = false;
    value(0; A) { }
}
table 51735 "MNC CQ Src1734"
{
    fields
    {
        field(1; Id; BigInteger) { }
        field(2; Other; Integer) { }
    }
}
table 51734 "MNC CQ T1734"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Looked; Enum "MNC CQ E1734")
        {
            FieldClass = FlowField;
            CalcFormula = lookup("MNC CQ Src1734".Id where(Other = field(Id)));
        }
    }
}
