// @expect AL0185 | Table 'MNC No Such Table' is missing
// A page names a SourceTable that does not exist.
page 50015 "MNC P211"
{
    PageType = List;
    SourceTable = "MNC No Such Table";
}
