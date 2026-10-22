// @expect AL0169 | The option value 'Removed' is not valid
// @expect AL0169 | The option value 'Removed' is not valid
// Removed is not a value of ObsoleteState for an enum value or an enum extension value.
enum 59710 "MNC U Enum 710"
{
    Extensible = true;
    value(0; A) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
}
enumextension 59711 "MNC U EnumExt 710" extends "MNC U Enum 710"
{
    value(1; B) { ObsoleteState = Removed; ObsoleteReason = 'r'; ObsoleteTag = '1.0'; }
}
