// @expect AL0666 | 'Run' is not available in runtime version '16.
// Runtime of the corpus apps since the runtime move: 16.1 on BC 27 (this error), 17.1 on BC 28 and 18.0 on BC 29 (the member exists there: the file compiles, so the case holds for BC 27 only).
// @until 27
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
