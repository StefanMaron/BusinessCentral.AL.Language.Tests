// @expect AL0390 | The date formula 'XYZ' must include a time unit. Time units can be: D,WD,W,M,Q, or Y. C specifies the current time unit based on date and can be used as a prefix to any of the time units.
// A DateFormula field whose InitValue is not a date formula.
table 50100 "MNC Garbled DateFormula Init"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Formula; DateFormula) { InitValue = 'xyz'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
