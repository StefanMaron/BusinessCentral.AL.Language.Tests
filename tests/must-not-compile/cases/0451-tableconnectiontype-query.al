// @expect AL0132 | 'TableConnectionType' does not contain a definition for 'Query'
// TableConnectionType has no member 'Query' (there is no query-type table connection).
codeunit 50000 "MNC Table Conn Query"
{
    procedure Kind(): TableConnectionType
    begin
        exit(TableConnectionType::Query);
    end;
}
