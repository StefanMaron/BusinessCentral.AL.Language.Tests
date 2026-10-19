// @expect AL0132 | 'HttpRequestType' does not contain a definition for 'AsInteger'
// @expect AL0122 | Cannot implicitly convert type 'Integer' to 'HttpRequestType'
// HttpRequestType is option-like: no AsInteger, and an Integer cannot be assigned. The same holds for PageStyle, AuditCategory, SecurityOperationResult and PageBackgroundTaskErrorLevel.
codeunit 59110 "MNC HttpReqType 0990"
{
    procedure Run1()
    var
        RequestType: HttpRequestType;
        Number: Integer;
    begin
        Number := RequestType.AsInteger();
        RequestType := Number;
    end;
}
