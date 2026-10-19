// Fixture for TestRelationOwnNamespaceDependency: the CalcFormula half of
// ALTRelationOwnDepWriters.al. Written in System.IO, the namespace of Base Application's
// "Config. Package Table" (8613), importing ALLanguage.Coverage.RelationNameCollision, which
// holds the same-named table 60991 (ALTRelationNameCollisionTables.al). The file's own namespace
// is searched first, so the FlowField counts Base Application's table.
// ALT Rel OwnDep IO Mod is the modify(...)-extended twin.

namespace System.IO;

using ALLanguage.Coverage.RelationNameCollision;

table 69229 "ALT Rel OwnDep IO"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Package Rows"; Integer)
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

table 69230 "ALT Rel OwnDep IO Mod"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Package Rows"; Integer)
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

tableextension 69231 "ALT Rel OwnDep IO Mod Ext" extends "ALT Rel OwnDep IO Mod"
{
    fields
    {
        modify("Package Rows")
        {
            Caption = 'Package Rows (modified)';
        }
    }
}
