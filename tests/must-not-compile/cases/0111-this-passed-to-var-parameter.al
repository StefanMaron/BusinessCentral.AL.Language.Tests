// @expect AL0130 | A 'var' argument must be an assignable variable
// this passed to a var parameter of another codeunit.
codeunit 50117 "MNC This Helper"
{
    procedure Touch(var Target: Codeunit "MNC This Owner")
    begin
    end;
}

codeunit 50118 "MNC This Owner"
{
    procedure PassSelf()
    var
        Helper: Codeunit "MNC This Helper";
    begin
        Helper.Touch(this);
    end;
}
