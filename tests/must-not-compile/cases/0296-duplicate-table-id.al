// @expect AL0264 | An application object of type 'Table' with ID '50109' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0264 | An application object of type 'Table' with ID '50109' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// Two tables have the same id.
table 50109 "MNC T296A"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

table 50109 "MNC T296B"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
