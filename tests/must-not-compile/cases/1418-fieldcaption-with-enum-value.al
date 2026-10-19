// @expect AL0166 | Argument 1: must be a member (field, property, or variable), not an expression or constant.
// Record.FieldCaption with an enum value instead of a field. Corpus issue 664 item 99 (microsoft/AL#7088; the source expected AL0118,
// the compiler today gives AL0166). Writer BO.
codeunit 51425 "MNC BO 1418"
{
    procedure Q(): Text
    var
        C: Record Customer;
    begin
        exit(C.FieldCaption("Application Method"::Manual));
    end;
}
