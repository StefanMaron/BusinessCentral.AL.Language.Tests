// @expect AL0873 | No enclosing loop within which to continue.
// Corpus #664 item 11. continue outside any loop is AL0873. The verbatim string part of the item is case 1386.
codeunit 51374 "MNC BM C1374"
{
    procedure P()
    begin
        continue;
    end;
}
