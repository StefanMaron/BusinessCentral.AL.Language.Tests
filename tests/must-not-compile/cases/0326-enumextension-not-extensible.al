// @expect AL0504 | The enum 'MNC E326' is not extensible
// An enum extension of an enum that is not extensible.
enum 50143 "MNC E326"
{
    Extensible = false;
    value(0; A) { }
}

enumextension 50144 "MNC EX326" extends "MNC E326"
{
    value(1; B) { }
}
