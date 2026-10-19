// @expect AL0133 | Argument 2: cannot convert from 'Text' to 'SecretText'
// A Text literal as the second argument of SecretStrSubstNo does not convert to SecretText (a Text variable does: types/lt-secret-text-from-text/SecretTextFromText.al).
codeunit 50990 "MNC SecretStrSubstNo Literal"
{
    procedure Probe(): Boolean
    var
        Secret: SecretText;
    begin
        Secret := SecretStrSubstNo('x=%1', 'literal');
        exit(Secret.IsEmpty());
    end;
}
