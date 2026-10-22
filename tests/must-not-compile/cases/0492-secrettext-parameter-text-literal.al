// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'SecretText'
// A Text literal passed to a SecretText parameter does not convert (a Text variable does: types/lt-secret-text-from-text/SecretTextFromText.al).
codeunit 50992 "MNC SecretText Param Literal"
{
    local procedure Take(Secret: SecretText): Boolean
    begin
        exit(Secret.IsEmpty());
    end;

    procedure Probe(): Boolean
    begin
        exit(Take('literal'));
    end;
}
