// @expect AL0595 | 'Codeunit "MNC DataSource Src 0988"' does not implement ITestDataSource
// @expect AL0185 | Interface 'ITestContext' is missing
// @expect AL0240 | The signature of procedure 'Run1' does not match the signature required by attribute 'TestDataSource': parameter 1 is expected to be of type 'interface ITestContext' but found type ''.
// @from 29
// @appjson {"runtime": "18.0"}
// On BC 29 the TestDataSource attribute names a codeunit that must implement ITestDataSource (an interface that the public symbols do not declare).
codeunit 59100 "MNC DataSource Src 0988"
{
}

codeunit 59101 "MNC TestDataSource29 0988"
{
    Subtype = Test;

    [TestDataSource(59100, 'Set')]
    procedure Run1(Context: Interface ITestContext)
    begin
    end;
}
