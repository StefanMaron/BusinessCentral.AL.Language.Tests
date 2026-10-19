// @expect AL0196 | The call is ambiguous between the method 'GetUrl(ClientType, [Text], [ObjectType], [Integer], [Table], [Boolean])' defined in Class 'System' by the extension '' and the method 'GetUrl(ClientType, Text, ObjectType, Integer, RecordRef, [Boolean])' defined in Class 'System' by the extension ''.
// System.GetUrl with a Variant that holds a record as the record argument (microsoft/AL issue 394): the call is ambiguous between the
// Table and the RecordRef overloads.
codeunit 51442 "MNC BP C1442"
{
    procedure P(): Text
    var
        V: Variant;
        C: Record Customer;
    begin
        V := C;
        exit(System.GetUrl(ClientType::Web, CompanyName(), ObjectType::Page, 21, V, false));
    end;
}
