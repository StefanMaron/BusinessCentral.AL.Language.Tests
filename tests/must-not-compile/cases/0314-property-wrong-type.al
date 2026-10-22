// @expect AL0219 | Syntax error, string literal expected. Enclose the text in single quotes (e.g., 'text').
// Caption given a number instead of text.
table 50130 "MNC T314"
{
    Caption = 5;
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
