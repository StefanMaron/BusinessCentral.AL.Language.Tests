// Fixture for TestRelationOwnNamespaceDependency: the control for ALTRelationOwnDepWriters.al
// with the two roles swapped. These tables are written in ALLanguage.Coverage.RelationOwnDepImported,
// whose bundle tables are named "Shipment Method" and "Shipping Agent", and import
// Microsoft.Foundation.Shipping, which holds Base Application's tables of the same names. The
// file's OWN namespace is searched first, so the names mean the bundle tables.
// ALT Rel OwnBundle Mod is the modify(...)-extended twin, as in ALTRelationOwnDepWriters.al.

namespace ALLanguage.Coverage.RelationOwnDepImported;

using Microsoft.Foundation.Shipping;

table 69226 "ALT Rel OwnBundle"
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

table 69227 "ALT Rel OwnBundle Mod"
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

tableextension 69228 "ALT Rel OwnBundle Mod Ext" extends "ALT Rel OwnBundle Mod"
{
    fields
    {
        modify("Method Code")
        {
            Caption = 'Method Code (modified)';
        }
    }
}
