// @expect AL0666 | 'TestDataSource' is not available in runtime version '16.0'. The supported runtime versions are: '18.0' or greater.
// @min-al 18
// @appjson {"runtime": "16.0"}
// The TestDataSource attribute needs runtime 18.0 (BC 29 and later). An app below that runtime gets AL0666 on every BC major (case 0987 is the AL 16 and 17 compilers' verdict for BC 27 and 28).
codeunit 59095 "MNC TestDataSource16 0999"
{
    Subtype = Test;

    [TestDataSource(1, 'Set')]
    procedure Run1(Context: Integer)
    begin
    end;
}
