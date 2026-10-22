// @expect AL0154 | The maximum length for a field of type 'Text' is 2048
// A table field of type Text[2049]. Text[2048] compiles.
table 51395 "MNC BN T1395"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Ok; Text[2048]) { }
        field(3; TooLong; Text[2049]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
