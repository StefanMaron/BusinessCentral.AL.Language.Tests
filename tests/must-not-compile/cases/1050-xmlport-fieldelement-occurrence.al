// @expect AL0124 | The property 'Occurrence' cannot be used in this context. Verify the property is available for the current object type.
// XmlPort fieldelement: Occurrence belongs to attributes; elements use MinOccurs and MaxOccurs.
table 50950 "MNC AG T950"
{
    fields { field(1; Id; Integer) { } field(2; Name; Text[30]) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
xmlport 50950 "MNC AG X950"
{
    schema
    {
        textelement(Root)
        {
            tableelement(Row; "MNC AG T950") { fieldelement(Id; Row.Id) { Occurrence = Required; } }
        }
    }
}
