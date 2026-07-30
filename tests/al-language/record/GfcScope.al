// Mirrors the shape a real asset registry uses: a row is identified by
// (Scope, SourceAppId, Name, StyleVariant).
enum 60231 "GFC Scope"
{
    Extensible = false;

    value(0; Tenant) { Caption = 'Tenant'; }
    value(1; Extension) { Caption = 'Extension'; }
}
