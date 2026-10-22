// @expect AL0231 | A member with ID '1' is already defined in Enum 'MNC Enum' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0231 | A member with ID '1' is already defined in Enum 'MNC Enum' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// Two enum values with one ordinal.
enum 50000 "MNC Enum"
{
    value(1; A) { }
    value(1; B) { }
}
