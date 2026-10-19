// @expect AL0185 | Page 'MNC Missing Page' is missing
// DrillDownPageId names a page that does not exist.
table 59990 "MNC X T" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
tableextension 59990 "MNC X TE" extends "MNC X T" { DrillDownPageId = "MNC Missing Page"; fields { field(59990; E; Integer) { } } }
