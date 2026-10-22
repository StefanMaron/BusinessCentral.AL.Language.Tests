// @expect AL0167 | The Property 'OptionOrdinalValues' can only be used if the property 'ExternalType' is set with any of the values of: 'Picklist,State,Status'
// @expect AL0167 | The Property 'OptionOrdinalValues' can only be used if the property 'TableType' is set with any of the values of: 'CRM,CDS'
// OptionOrdinalValues needs TableType CRM or CDS and an ExternalType of Picklist, State or Status.
table 59696 "MNC U 696"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Opt; Option) { OptionMembers = Alpha, Beta, Gamma; OptionOrdinalValues = 5, 10, 20; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
