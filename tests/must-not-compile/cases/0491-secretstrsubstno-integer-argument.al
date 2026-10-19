// @expect AL0133 | Argument 2: cannot convert from 'Integer' to 'SecretText'
// An Integer as an argument of SecretStrSubstNo does not convert to SecretText.
codeunit 50991 "MNC SecretStrSubstNo Integer"
{
    procedure Probe(): Boolean
    var
        Secret: SecretText;
    begin
        Secret := SecretStrSubstNo('x=%1', 42);
        exit(Secret.IsEmpty());
    end;
}
