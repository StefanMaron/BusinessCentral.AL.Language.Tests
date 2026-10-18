// @expect AL0124 | The property 'MaxLength' cannot be used in this context
// MaxLength is a modifier of Caption only; on a field it is not a property.
table 59698 "MNC U 698"
{
    fields { field(1; Id; Integer) { } field(2; Txt; Text[30]) { MaxLength = 5; } }
    keys { key(PK; Id) { Clustered = true; } }
}
