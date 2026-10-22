// @expect AL0197 | An application object of type 'Table' with name 'MNC Same Table' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// @expect AL0197 | An application object of type 'Table' with name 'MNC Same Table' is already declared by the extension 'Must Not Compile by AL Language (1.0.0.0)'
// A table and a table extension... two tables of one name in one app (different ids).
table 50000 "MNC Same Table" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
table 50001 "MNC Same Table" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
