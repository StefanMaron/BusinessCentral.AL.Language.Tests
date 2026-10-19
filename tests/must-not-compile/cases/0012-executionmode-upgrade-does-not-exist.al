// @expect AL0132 | 'ExecutionMode' does not contain a definition for 'Upgrade'
// ExecutionMode has the members Standard and Debug only; 'Upgrade' is not one of them.
codeunit 50000 "MNC Exec Mode"
{
    procedure Mode(): ExecutionMode
    begin
        exit(ExecutionMode::Upgrade);
    end;
}
