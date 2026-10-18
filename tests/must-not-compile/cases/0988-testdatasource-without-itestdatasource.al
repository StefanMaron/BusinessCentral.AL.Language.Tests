// @expect AL0595 | 'Codeunit "MNC DataSource Src 0988"' does not implement ITestDataSource
// @from 29
// @appjson {"runtime": "18.0"}
// On BC 29 the TestDataSource attribute names a codeunit that must implement ITestDataSource.
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
