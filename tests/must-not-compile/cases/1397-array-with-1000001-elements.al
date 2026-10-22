// @expect AL0146 | The maximum number of array elements is 1000000. Actual number is 1000001
// An array of 1,000,001 elements. 1,000,000 elements compile.
codeunit 51397 "MNC BN C1397"
{
    var
        Ok: array[1000000] of Integer;
        TooBig: array[1000001] of Integer;
}
