// @expect AL0155 | A member of type EnumValue with name 'A' is already defined in Enum 'MNC Enum' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type EnumValue with name 'A' is already defined in Enum 'MNC Enum' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// Two enum values with one name.
enum 50000 "MNC Enum"
{
    value(1; A) { }
    value(2; A) { }
}
