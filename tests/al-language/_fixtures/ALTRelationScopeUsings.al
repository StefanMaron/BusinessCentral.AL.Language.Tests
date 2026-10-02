// Fixture for TestRelationTargetNamespaceScope. The same two unqualified names as
// ALTRelationScopeSameNamespace.al, written from a DIFFERENT namespace that imports the Base
// Application namespaces holding them. The same-named tables of
// ALTRelationNameCollisionTables.al live in ALLanguage.Coverage.RelationNameCollision, which
// this file does not import, so only the Base Application tables are in scope here.
// ALT Rel Usings Mod is the modify(...)-extended twin; see ALTRelationScopeSameNamespace.al.

namespace ALLanguage.Coverage.RelationScopeUsings;

using Microsoft.Foundation.Shipping;
using System.IO;

table 69201 "ALT Rel Usings"
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

table 69203 "ALT Rel Usings Mod"
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

tableextension 69205 "ALT Rel Usings Mod Ext" extends "ALT Rel Usings Mod"
{
    fields
    {
        modify("Agent Code")
        {
            Caption = 'Agent Code (modified)';
        }
    }
}
