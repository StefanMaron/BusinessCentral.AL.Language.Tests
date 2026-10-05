// Fixture for TestRelationOwnNamespaceDependency. A table written in Microsoft.Foundation.Shipping,
// the namespace of Base Application's "Shipping Agent" (291), importing
// ALLanguage.Coverage.RelationNameCollision, which holds the same-named table 60990
// (ALTRelationNameCollisionTables.al). An unqualified name written here is found in the file's
// OWN namespace first, so it means Base Application's table 291, not the imported 60990.
//
// ALT Rel OwnDep Mod is the modify(...)-extended twin: a table nobody modifies is described to
// the platform by the compiler's own metadata, one a modify(...) extension touches is described
// a field at a time from its AL source. Same names, same expected answers. The extension also
// adds a field, written in the same file.

namespace Microsoft.Foundation.Shipping;

using ALLanguage.Coverage.RelationNameCollision;

table 69222 "ALT Rel OwnDep"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; "Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
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
        field(1; Code; Code[20]) { }
        field(2; "Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
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
        field(69225; "Ext Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        modify("Agent Code")
        {
            Caption = 'Agent Code (modified)';
        }
    }
}
