// @expect AL0296 | The application object or method 'Unwrap' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// SecretText.Unwrap named from a Cloud app (the method has scope OnPrem).
codeunit 50119 "MNC Secret Unwrap"
{
    procedure Reveal(Secret: SecretText): Text
    begin
        exit(Secret.Unwrap());
    end;
}
