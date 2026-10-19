// Fixture for TestRelationTargetNamespaceScope. A tableextension declared in
// ALLanguage.Coverage.RelationNameCollision, the namespace of the same-named "Shipping Agent"
// (60990), extending a table from ALLanguage.Coverage.RelationScopeUsings, whose own file
// imports Microsoft.Foundation.Shipping instead. The field this extension adds writes an
// unqualified "Shipping Agent" in the EXTENSION's file, so its relation is the local table, and
// the FlowField it adds counts the local "Config. Package Table" (60991), not the one System.IO
// imports into table 69203's own file.

namespace ALLanguage.Coverage.RelationNameCollision;

using ALLanguage.Coverage.RelationScopeUsings;

tableextension 69206 "ALT Rel Cross NS Ext" extends "ALT Rel Usings Mod"
{
    fields
    {
        field(69206; "Cross NS Agent Code"; Code[10])
        {
            TableRelation = "Shipping Agent";
        }
        field(69208; "Cross NS Package Rows"; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("Config. Package Table" where("Package Code" = field(Code)));
        }
    }
}
