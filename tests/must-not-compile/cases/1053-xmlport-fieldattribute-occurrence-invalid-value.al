// @expect AL0169 | The option value 'Sometimes' is not valid. Check the enum definition for valid values.
// XmlPort fieldattribute: Occurrence takes Optional or Required.
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
            tableelement(Row; "MNC AG T950") { fieldattribute(Id; Row.Id) { Occurrence = Sometimes; } }
        }
    }
}
