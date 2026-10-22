// @expect AL0155 | A member of type EnumValue with name 'Test' is already defined in EnumExtension 'MNC BN EX1398'
// @expect AL0155 | A member of type EnumValue with name 'Test' is already defined in EnumExtension 'MNC BN EX1398'
// An enum extension declares `value(51045; Test)` twice (microsoft/AL issue 6678): the compiler reports the duplicate name (AL0155) on both
// declarations and no duplicate ordinal (AL0231 comes only when the names differ: case 1399).
enum 51398 "MNC BN E1398"
{
    Extensible = true;
    value(0; A0) { }
}

enumextension 51399 "MNC BN EX1398" extends "MNC BN E1398"
{
    value(51045; Test) { }
    value(51045; Test) { }
}
