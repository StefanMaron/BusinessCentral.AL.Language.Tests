// Fixture for TestRelationOwnNamespaceDependency: the control for ALTRelationOwnDepWriters.al
// and ALTRelationOwnDepWritersIO.al with the two roles swapped. These tables are written in
// ALLanguage.Coverage.RelationNameCollision, whose own tables are "Shipping Agent" (60990) and
// "Config. Package Table" (60991), and import Microsoft.Foundation.Shipping and System.IO, which
// hold Base Application's tables of the same names. The file's OWN namespace is searched first,
// so the names mean 60990 and 60991. ALT Rel OwnBundle Mod is the modify(...)-extended twin.

namespace ALLanguage.Coverage.RelationNameCollision;

using Microsoft.Foundation.Shipping;
using System.IO;

table 69226 "ALT Rel OwnBundle"
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

table 69227 "ALT Rel OwnBundle Mod"
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

tableextension 69228 "ALT Rel OwnBundle Mod Ext" extends "ALT Rel OwnBundle Mod"
{
    fields
    {
        modify("Agent Code")
        {
            Caption = 'Agent Code (modified)';
        }
    }
}
