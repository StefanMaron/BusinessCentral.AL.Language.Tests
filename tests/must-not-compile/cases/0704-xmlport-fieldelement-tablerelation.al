// @expect AL0124 | The property 'TableRelation' cannot be used in this context
// TableRelation is not a property of an XmlPort field element (the table field carries it).
table 59704 "MNC U 704" { fields { field(1; Id; Integer) { } field(2; Rel; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
xmlport 59704 "MNC U Xml 704"
{
    schema { textelement(Root) { tableelement(Row; "MNC U 704") { fieldelement(Rel; Row.Rel) { TableRelation = "MNC U 704".Id; } } } }
}
