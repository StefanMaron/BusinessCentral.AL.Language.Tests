// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-calcformula-property
// Scope: in-scope
// Fixtures used: Item Ledger Entry (32)
//
// The TARGET side of the pair. "TXC Cust Stats Ext" sums this field and filters on it from a
// CalcFormula declared on another table, so the field has to be resolvable by name from a
// formula that lives outside the extension that added it.
//
// No SumIndexFields key: under this app's runtime (16.0) alc raises
//   AL0423: The property 'SumIndexFields' can only be set if the specified fields are from
//           the same table
// for a key whose key fields are the extended table's and whose SumIndexFields entry is the
// field this extension adds -- measured on BC 28.4.53241.0 with alc 17.0.39.53543, and it
// compiles under runtime 17.0. The sums below do not need one: all seven tests pass on a real
// service tier without it.
tableextension 60822 "TXC ILE Ext" extends "Item Ledger Entry"
{
    fields
    {
        field(60829; "TXC Ext Weight"; Decimal)
        {
            DataClassification = SystemMetadata;
        }
    }
}
