// @expect AL0231 | A member with ID '51045' is already defined in EnumExtension 'MNC BN EX1399'
// @expect AL0231 | A member with ID '51045' is already defined in EnumExtension 'MNC BN EX1399'
// An enum extension declares the ordinal 51045 twice under two names. The clash with an ordinal of the base enum is case 0304.
enum 51398 "MNC BN E1399"
{
    Extensible = true;
    value(0; A0) { }
}

enumextension 51399 "MNC BN EX1399" extends "MNC BN E1399"
{
    value(51045; Test2) { }
    value(51045; Test3) { }
}
