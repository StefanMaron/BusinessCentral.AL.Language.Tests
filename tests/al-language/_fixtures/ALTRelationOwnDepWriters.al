// Fixture for TestRelationOwnNamespaceDependency. Tables written in
// Microsoft.Foundation.Shipping, the namespace of Base Application's "Shipment Method" (10) and
// "Shipping Agent" (291), and importing ALLanguage.Coverage.RelationOwnDepImported, which holds
// a bundle table of each name (ALTRelationOwnDepImportedTables.al). An unqualified name written
// here is found in the file's OWN namespace first, so it means the Base Application table, not
// the imported one.
//
// ALT Rel OwnDep Mod is the modify(...)-extended twin: a table nobody modifies is described to
// the platform by the compiler's own metadata, one a modify(...) extension touches is described
// a field at a time from its AL source. Same names, same expected answers.

namespace Microsoft.Foundation.Shipping;

using ALLanguage.Coverage.RelationOwnDepImported;

table 69222 "ALT Rel OwnDep"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Method Code"; Code[10])
        {
            TableRelation = "Shipment Method";
        }
        field(3; "Agent Rows"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Shipping Agent" where(Code = field(Code)));
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 69223 "ALT Rel OwnDep Mod"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; "Method Code"; Code[10])
        {
            TableRelation = "Shipment Method";
        }
        field(3; "Agent Rows"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Shipping Agent" where(Code = field(Code)));
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

tableextension 69224 "ALT Rel OwnDep Mod Ext" extends "ALT Rel OwnDep Mod"
{
    fields
    {
        field(69225; "Ext Method Code"; Code[10])
        {
            TableRelation = "Shipment Method";
        }
        modify("Method Code")
        {
            Caption = 'Method Code (modified)';
        }
    }
}
