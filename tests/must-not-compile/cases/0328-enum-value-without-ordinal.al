// @expect AL0104 | Syntax error, ';' expected
// @expect AL0114 | Syntax error, integer literal expected. Provide a numeric value (e.g., 0, 1, 42).
// An enum value without an ordinal.
enum 50146 "MNC E328"
{
    value(A) { }
}
