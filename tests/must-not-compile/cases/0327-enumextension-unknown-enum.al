// @expect AL0247 | The target Enum 'MNC No Such Enum' for the extension object is not found
// An enum extension of an enum that does not exist.
enumextension 50145 "MNC EX327" extends "MNC No Such Enum"
{
    value(1; B) { }
}
