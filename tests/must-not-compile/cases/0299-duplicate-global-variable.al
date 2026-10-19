// @expect AL0155 | A member of type GlobalVariable with name 'X' is already defined in Codeunit 'MNC C299' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// @expect AL0155 | A member of type GlobalVariable with name 'X' is already defined in Codeunit 'MNC C299' by the extension 'Must Not Compile by AL Language (1.0.0.0)'.
// A codeunit declares a global variable twice.
codeunit 50112 "MNC C299"
{
    var
        X: Integer;
        X: Text;
}
