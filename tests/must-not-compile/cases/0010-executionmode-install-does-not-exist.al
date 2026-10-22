// @expect AL0132 | 'ExecutionMode' does not contain a definition for 'Install'
// ExecutionMode has the members Standard and Debug only; 'Install' is not one of them.
codeunit 50000 "MNC Exec Mode"
{
    procedure Mode(): ExecutionMode
    begin
        exit(ExecutionMode::Install);
    end;
}
