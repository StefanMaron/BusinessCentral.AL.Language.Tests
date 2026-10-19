// Fixture for TestRelationTargetNamespaceScope. A table written in the SAME namespace as the
// colliding "Shipping Agent" (60990) and "Config. Package Table" (60991) of
// ALTRelationNameCollisionTables.al, with no using for Microsoft.Foundation.Shipping or
// System.IO. An unqualified name in its TableRelation and CalcFormula can only mean the
// same-namespace table.
//
// ALT Rel Same NS Mod carries the same fields and a tableextension whose
// modify(...) changes one of them. That is a second table shape: a table nobody modifies is
// described to the platform by the compiler's own metadata, one a modify(...) extension touches
// is described a field at a time from its AL source.

namespace ALLanguage.Coverage.RelationNameCollision;

table 69200 "ALT Rel Same NS"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        field(3; "Package Rows"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Config. Package Table" where("Package Code" = field(Code)));
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 69202 "ALT Rel Same NS Mod"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        field(3; "Package Rows"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Config. Package Table" where("Package Code" = field(Code)));
        }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

tableextension 69204 "ALT Rel Same NS Mod Ext" extends "ALT Rel Same NS Mod"
{
    fields
    {
        modify("Agent Code")
        {
            Caption = 'Agent Code (modified)';
        }
    }
}
