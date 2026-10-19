// @expect AL0623 | #endif directive expected.
// @expect AL0622 | #endregion directive expected.
// Corpus #664 item 29. A #region that starts outside an #if and ends inside it: AL0623 at the #endregion and AL0622 at the end of the file.
codeunit 51383 "MNC BM C1383"
{
    #region A
    procedure P(): Integer
    begin
#if BC27PLUS
        exit(1);
    #endregion
#endif
        exit(3);
    end;
}
