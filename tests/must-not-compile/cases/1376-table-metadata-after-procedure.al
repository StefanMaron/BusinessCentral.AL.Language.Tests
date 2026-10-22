// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0104 | Syntax error, 'fields' expected
// @expect AL0926 | The 'fields' section is not valid here. In a table object, the expected section order is: fields, keys, fieldgroups. Metadata sections must appear before var declarations, triggers, and procedures.
// @expect AL0926 | The 'keys' section is not valid here. In a table object, the expected section order is: fields, keys, fieldgroups. Metadata sections must appear before var declarations, triggers, and procedures.
// Corpus #664 item 15. A table whose fields and keys come after a procedure: AL0926 for each section plus AL0104 at the procedure.
// The AL 30.0 compiler gives the same on BC 27, 28 and 29 (runtime 16.1, 17.1, 18.0); the lead said BC 29 only.
table 51376 "MNC BM T1376"
{
    procedure P()
    begin
    end;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
