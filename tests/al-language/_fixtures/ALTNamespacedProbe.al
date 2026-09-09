// Fixture for TestCodeunitMetadataVirtualTable: the one codeunit in this application declared
// inside a namespace, so the "CodeUnit Metadata" (2000000137) "AL Namespace" column can be
// read against a codeunit that HAS one.
//
// Every other object in this suite sits in a file with no namespace statement and therefore
// reports the empty string. Asserting only that would not distinguish a column carrying a real
// per-object value from a column that is blank for everyone, so this fixture supplies the
// other half of the comparison and nothing else depends on it.
//
// The namespace is deliberately multi-segment: it pins that the column reports the full
// dotted name rather than the last segment or the first.

namespace ALLanguage.Coverage.MetadataProbes;

codeunit 60288 "ALT Namespaced Probe"
{
    procedure Ping(): Integer
    begin
        exit(1);
    end;
}
