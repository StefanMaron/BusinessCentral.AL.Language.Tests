// @expect AL0118 | The name 'CreateSequentialGuid' does not exist in the current context.
// AL has no CreateSequentialGuid (only CreateGuid).
codeunit 50000 "MNC Codeunit"
{
    procedure Make(): Guid
    begin
        exit(CreateSequentialGuid());
    end;
}
