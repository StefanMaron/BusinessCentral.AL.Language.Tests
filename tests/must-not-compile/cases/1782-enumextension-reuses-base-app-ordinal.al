// @expect AL0231 | A member with ID '1' is already defined in Enum 'Sales Line Type' by the extension 'Base Application by Microsoft
// Corpus #670 item 69 (AL issue 5793). An enumextension of an enum of another app (Base Application "Sales Line Type") that reuses an
// ordinal of the base enum is refused with AL0231 at compile time, on BC 27, 28 and 29. An unused ordinal (6) compiles: its place in
// Ordinals() is pinned in tests/al-language/enum/lt-cw-enum-ordinals/CwEnumOrdinals.al. Same-app form: case 0304.
enumextension 51782 "MNC CW EX1782" extends "Sales Line Type"
{
    value(1; "MNC CW Dup") { }
}
