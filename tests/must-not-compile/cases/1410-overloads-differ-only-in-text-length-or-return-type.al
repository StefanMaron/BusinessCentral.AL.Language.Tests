// @expect AL0440 | The Codeunit 'MNC BO 1410' already defines a method called 'P' with the same parameter types
// @expect AL0440 | The Codeunit 'MNC BO 1410' already defines a method called 'P' with the same parameter types
// @expect AL0440 | The Codeunit 'MNC BO 1410' already defines a method called 'P' with the same parameter types
// @expect AL0440 | The Codeunit 'MNC BO 1410' already defines a method called 'F' with the same parameter types
// Overloads that differ only in the length of a Text parameter (Text, Text[250], Text[100]) are one signature: AL0440 on every later
// declaration (the third gets it twice, once per earlier one). Overloads that differ only in the return type (Record Customer, Record
// Vendor) are one signature too. Corpus issue 664 items 78 and 81 (microsoft/AL#6522, #6701). Writer BO. (4 diagnostics)
codeunit 51410 "MNC BO 1410"
{
    procedure P(var T: Text) begin end;
    procedure P(var T: Text[250]) begin end;
    procedure P(var T: Text[100]) begin end;

    procedure F(): Record Customer begin end;
    procedure F(): Record Vendor begin end;
}
