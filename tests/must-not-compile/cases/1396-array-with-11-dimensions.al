// @expect AL0368 | The maximum number of array dimensions is 10.
// An array with 11 dimensions. 10 dimensions compile.
codeunit 51396 "MNC BN C1396"
{
    var
        A10: array[2, 2, 2, 2, 2, 2, 2, 2, 2, 2] of Integer;
        A11: array[2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2] of Integer;
}
