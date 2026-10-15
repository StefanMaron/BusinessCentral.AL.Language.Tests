// @expect AL0155 | A member of type Key with name 'PK' is already defined in Table 'MNC T297' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type Key with name 'PK' is already defined in Table 'MNC T297' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A table has two keys with the same name.
table 50110 "MNC T297"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } key(PK; Name) { } }
}
