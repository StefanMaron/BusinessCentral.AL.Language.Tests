// @expect AL0185 | Table 'No.Series' is missing
// A TableRelation that misspells the table ("No.Series" for "No. Series"). Other places of an unknown table: cases 0202, 0211, 0216.
// Corpus issue 664 item 104 (microsoft/AL#97). Writer BO.
table 51430 "MNC BO 1423"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; S; Code[20]) { TableRelation = "No.Series".Code; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
