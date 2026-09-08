// Fixture for TestCodeunitMetadataVirtualTable: a codeunit that states its Subtype as a
// QUOTED identifier, naming the subtype the "CodeUnit Metadata" (2000000137) SubType column
// has no member for.
//
// AL accepts `Subtype = "Install";` exactly as it accepts `Subtype = Install;` -- quoting an
// identifier is a lexical choice, not a different value. ALTInstallProbe.al pins what the
// column reports for the bare spelling; this fixture asks whether the quoted spelling is
// reported the same way, and whether a codeunit declared this way still takes part in the
// table's enumeration like any other.
//
// The install triggers are deliberately empty. Nothing here should change company state --
// the fixture exists to be READ through CodeUnit Metadata, not to install anything.

codeunit 60828 "ALT Quoted Install Probe"
{
    Subtype = "Install";

    trigger OnInstallAppPerCompany()
    begin
    end;

    trigger OnInstallAppPerDatabase()
    begin
    end;
}
