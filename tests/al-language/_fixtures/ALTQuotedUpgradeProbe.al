// Fixture for TestCodeunitMetadataVirtualTable: a codeunit that states its Subtype as a
// QUOTED identifier, naming a subtype the "CodeUnit Metadata" (2000000137) SubType column DOES
// have a member for.
//
// It is the counterpart of ALTQuotedInstallProbe.al. That one quotes Install, the subtype the
// column names no member for; this one quotes Upgrade, which the column names. Together they
// separate two questions that would otherwise be confounded: what the column does with a
// quoted identifier, and what it does with Install.
//
// The upgrade trigger is deliberately empty. Nothing here should change company state -- the
// fixture exists to be READ through CodeUnit Metadata.

codeunit 60829 "ALT Quoted Upgrade Probe"
{
    Subtype = "Upgrade";

    trigger OnUpgradePerCompany()
    begin
    end;
}
