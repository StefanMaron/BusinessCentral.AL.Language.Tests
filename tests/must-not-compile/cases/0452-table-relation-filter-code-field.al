// @expect AL0186 | Reference 'Tag' in application object 'MNC TR Ref 0452' does not exist
// @expect AL0186 | Reference 'Tag' in application object 'MNC TR Ref 0452' does not exist
// A TableRelation where() clause with filter() of identifiers on a Code field of the related table (on an enum or option field the same text compiles).
table 59882 "MNC TR Ref 0452"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Tag; Code[10]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 59883 "MNC TR Src 0452"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Ref; Code[10]) { TableRelation = "MNC TR Ref 0452".Id where (Tag = filter(A | D)); }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
