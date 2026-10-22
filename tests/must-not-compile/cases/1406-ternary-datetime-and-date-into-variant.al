// @expect AL0122 | Cannot implicitly convert type 'Date' to 'DateTime'. Use an explicit conversion or change the type.
// `V := Cond ? CurrentDateTime() : Today()` into a Variant: the true branch sets the type (DateTime) and the Date branch does not convert,
// even though the target is a Variant (microsoft/AL issue 7937).
codeunit 51406 "MNC BN C1406"
{
    procedure Run1(Cond: Boolean)
    var
        V: Variant;
    begin
        V := Cond ? CurrentDateTime() : Today();
    end;
}
