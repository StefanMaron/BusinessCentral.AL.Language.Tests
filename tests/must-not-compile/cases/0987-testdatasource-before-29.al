// @expect AL0112 | TestDataSource is not a valid attribute
// @until 28
// The TestDataSource attribute exists from BC 29.
codeunit 59095 "MNC TestDataSource 0987"
{
    Subtype = Test;

    [TestDataSource(1, 'Set')]
    procedure Run1(Context: Integer)
    begin
    end;
}
