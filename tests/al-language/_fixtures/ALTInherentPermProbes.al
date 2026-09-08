// Fixtures for TestCodeunitMetadataVirtualTable: two codeunits that declare an inherent
// permission / entitlement, so the "CodeUnit Metadata" (2000000137) InherentPermissions and
// InherentEntitlements columns can be read against a codeunit that states one.
//
// On a codeunit AL accepts exactly one permission kind for these two properties: X (Execute).
// Anything else is error AL0195, "Invalid permission kind. Expected: 'X'" -- which is why
// neither fixture states RIMD, and why the two properties are split across two codeunits
// rather than both declared on one: keeping them separate is what proves the two columns
// are read independently instead of one being echoed into the other.

codeunit 60138 "ALT Inherent Perm Probe"
{
    InherentPermissions = X;

    procedure Ping(): Integer
    begin
        exit(1);
    end;
}

codeunit 60287 "ALT Inherent Ent Probe"
{
    InherentEntitlements = X;

    procedure Ping(): Integer
    begin
        exit(2);
    end;
}
