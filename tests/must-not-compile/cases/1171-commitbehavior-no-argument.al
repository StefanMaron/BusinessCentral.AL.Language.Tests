// The CommitBehavior attribute needs its one argument (corpus issue 647 item 4, writer AV).
// @expect AL0238 | No overload for attribute 'CommitBehavior' expects 0 arguments
codeunit 51171 "MNC AV CommitBehavior NoArg"
{
    [CommitBehavior()]
    procedure Probe()
    begin
    end;
}
