// @expect AL0413 | Procedure 'Calc' cannot have a body.
// @until 28
// Runtime 18.0 (BC 29) accepts an interface member with a body (checked with AL 30.0.42.60748-beta); runtime 17.1 and earlier do not.
// An interface member has a body.
interface "MNC I325"
{
    procedure Calc(A: Integer): Integer
    begin
    end;
}
