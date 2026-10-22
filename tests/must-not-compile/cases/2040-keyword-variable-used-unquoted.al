// @expect AL0224 | Expression expected. Provide a valid expression (variable, constant, calculation, or method call).
// @expect AL0104 | Syntax error, 'then' expected
// A variable named by the keyword If (accepted in the var section, see tests/al-language/misc/lt-bn3-identifiers/Bn3Labels.al
// QT_KeywordsAsVariableNames_Compile_AndHoldValues) used UNQUOTED in a statement: the compiler reads it as the if statement.
// Probe: al-runtime-rs PR 5642 (writer QT); measured with AL 30.0.42.60748-beta for BC 27, 28 and 29.
codeunit 50100 "MNC QT 2040"
{
    procedure P()
    var
        "If": Integer;
    begin
        If := 1;
    end;
}
