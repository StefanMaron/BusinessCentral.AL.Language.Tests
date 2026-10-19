// Fixture for TestRelationTargetNamespaceScope. The same two unqualified names, written from a
// THIRD namespace that has no table of its own by those names and imports the namespace of
// ALTRelationNameCollisionTables.al (ALLanguage.Coverage.RelationNameCollision), not a Base
// Application one. The name means the table that using brings in: 60990 and 60991, same app.
// ALT Rel Third Mod is the modify(...)-extended twin; see ALTRelationScopeSameNamespace.al.

namespace ALLanguage.Coverage.RelationScopeThird;

using ALLanguage.Coverage.RelationNameCollision;

table 69214 "ALT Rel Third"
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

table 69215 "ALT Rel Third Mod"
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

tableextension 69216 "ALT Rel Third Mod Ext" extends "ALT Rel Third Mod"
{
    fields
    {
        modify("Agent Code")
        {
            Caption = 'Agent Code (modified)';
        }
    }
}
