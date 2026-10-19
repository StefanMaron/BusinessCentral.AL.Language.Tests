// @expect AL0456 | The number of option ordinal values is not valid. There must be as many option ordinal values as there are option members
// OptionOrdinalValues needs one value per option member.
table 59700 "MNC U 700"
{
    TableType = CDS;
    ExternalName = 'x';
    fields
    {
        field(1; Id; Guid) { ExternalName = 'id'; ExternalType = 'Uniqueidentifier'; ExternalAccess = Insert; }
        field(2; Opt; Option) { ExternalName = 'o'; ExternalType = 'Picklist'; OptionMembers = Alpha, Beta, Gamma; OptionOrdinalValues = 5, 10; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
