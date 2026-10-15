// @expect AL0231 | A member with ID '0' is already defined in Enum 'MNC E304' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0231 | A member with ID '0' is already defined in EnumExtension 'MNC EX304' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// An enum extension reuses an ordinal of its base enum.
enum 50118 "MNC E304"
{
    Extensible = true;
    value(0; A) { }
}

enumextension 50119 "MNC EX304" extends "MNC E304"
{
    value(0; B) { }
}
