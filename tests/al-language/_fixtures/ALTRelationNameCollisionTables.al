// Fixture for TestRelationTargetNameCollision: two tables that reuse the NAMES of Base
// Application tables under this app's own namespace. AL allows that since namespaces arrived,
// and it is exactly the shape that must not change what a Base Application field relates to.
//
// - "Shipping Agent" shares its name with Base Application table 291, the TableRelation target
//   of Customer."Shipping Agent Code" (field 31).
// - "Config. Package Table" shares its name with Base Application table 8613, the CalcFormula
//   source of "Config. Package"."No. of Tables" (field 5). It declares "Package Code" so a
//   lookup that picked it by name would still find the where() field and silently count here.

namespace ALLanguage.Coverage.RelationNameCollision;

table 60990 "Shipping Agent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 60991 "Config. Package Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Package Code"; Code[20]) { }
        field(2; "Table ID"; Integer) { }
    }

    keys
    {
        key(PK; "Package Code", "Table ID") { Clustered = true; }
    }
}
