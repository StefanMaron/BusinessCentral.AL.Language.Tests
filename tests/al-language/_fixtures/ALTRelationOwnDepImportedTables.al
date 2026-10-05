// Fixture for TestRelationOwnNamespaceDependency: two tables that reuse the NAMES of Base
// Application tables under this app's own namespace, which other files import with `using`.
//
// - "Shipment Method" shares its name with Base Application table 10, the target the
//   writers in ALTRelationOwnDepWriters.al and ALTRelationOwnDepImportedWriters.al name in a
//   TableRelation.
// - "Shipping Agent" shares its name with Base Application table 291. Its primary key is
//   (Code, Seq) so one Code can carry two rows here while the Base Application table (primary
//   key Code) carries one: a count over a Code tells the two tables apart.
//
// The Base Application tables live in Microsoft.Foundation.Shipping. The sibling fixtures of
// TestRelationTargetNamespaceScope put the same-named tables in
// ALLanguage.Coverage.RelationNameCollision; this namespace is separate so that file's tests
// keep their meaning.

namespace ALLanguage.Coverage.RelationOwnDepImported;

table 69220 "Shipment Method"
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

table 69221 "Shipping Agent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Seq; Integer) { }
    }

    keys
    {
        key(PK; Code, Seq) { Clustered = true; }
    }
}
