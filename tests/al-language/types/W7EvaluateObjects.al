// Batch 7 probes: an enum with names and ordinals that differ, and a table of DateFormula fields with InitValue. Not tests.
enum 68543 "W7 Mixed"
{
    Extensible = true;

    value(0; "First One") { }
    value(5; Second) { }
    value(10; third) { }
}

table 68544 "W7 DF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; F1Y; DateFormula) { InitValue = '1Y'; }
        field(3; F1MBrackets; DateFormula) { InitValue = '<1M>'; }
        field(4; FCM; DateFormula) { InitValue = 'CM'; }
        field(5; FNone; DateFormula) { }
        field(6; FEmptyInit; DateFormula) { InitValue = ''; }
        field(7; F1D; DateFormula) { InitValue = '1D'; }
        field(8; FNegative; DateFormula) { InitValue = '-1D'; }
        field(9; FMixed; DateFormula) { InitValue = '1D+1W'; }
        field(10; FLower; DateFormula) { InitValue = '1d'; }
        field(11; FSpaces; DateFormula) { InitValue = ' 1D '; }
        field(12; FCombined; DateFormula) { InitValue = '<-CM+1D>'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
