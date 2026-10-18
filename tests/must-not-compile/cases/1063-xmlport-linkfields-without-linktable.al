// @expect AL0171 | The property value 'Par = field(Id)' on property 'LinkFields' is not valid.
// An XmlPort table element sets LinkFields but no LinkTable.
table 51063 "MNC AH T1063"
{
    fields
    {
        field(1; Id; Code[20]) { }
        field(2; Lvl; Decimal) { }
        field(3; Opt; Option) { OptionMembers = A,B; }
        field(4; Par; Code[20]) { }
        field(5; Txt; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
xmlport 51063 "MNC AH X1063"
{
    schema
    {
        textelement(Root)
        {
            tableelement(Par; "MNC AH T1063")
            {
                fieldelement(Id; Par.Id) { }
                tableelement(Chi; "MNC AH T1063")
                {
                    LinkFields = Par = field(Id);
                    fieldelement(Id; Chi.Id) { }
                }
            }
        }
    }
}
