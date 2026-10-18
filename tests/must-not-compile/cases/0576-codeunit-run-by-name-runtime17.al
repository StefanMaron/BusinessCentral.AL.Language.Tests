// @expect AL0666 | 'Run' is not available in runtime version '16.0'.
// Codeunit.Run with the codeunit name as a text (runtime 17.0 or greater; the corpus apps declare runtime 16.0).
codeunit 50576 "MNC O 0576"
{
    procedure Probe(): Boolean
    var
        Customer: Record Customer;
    begin
        exit(Codeunit.Run('Customer-Mgt.', Customer));
    end;
}
