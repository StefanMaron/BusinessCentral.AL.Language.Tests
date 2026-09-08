// Fixtures for TestCodeunitMetadataVirtualTable: four codeunits that differ ONLY in what
// they declare for TestIsolation, so the "CodeUnit Metadata" (2000000137) TestIsolation
// column can be read against something other than one value.
//
// AL accepts TestIsolation only on a codeunit whose Subtype is TestRunner -- declaring it
// anywhere else is error AL0223, "The Property 'TestIsolation' can only be used if the
// property 'Subtype' is set to 'TestRunner'". So a TestRunner is the only shape that can
// state the property at all, and all four below are TestRunner for that reason.
//
// Three of them declare one of the three values AL accepts. The fourth declares none, which
// is what pins the column's answer for a codeunit that leaves the property out -- the case
// every ordinary codeunit in the application is in.
//
// The OnRun triggers are deliberately empty: nothing here runs any test. These exist to be
// READ through CodeUnit Metadata.

codeunit 60036 "ALT Iso Runner Disabled"
{
    Subtype = TestRunner;
    TestIsolation = Disabled;
}

codeunit 60048 "ALT Iso Runner Codeunit"
{
    Subtype = TestRunner;
    TestIsolation = Codeunit;
}

codeunit 60049 "ALT Iso Runner Function"
{
    Subtype = TestRunner;
    TestIsolation = Function;
}

codeunit 60137 "ALT Iso Runner Unstated"
{
    Subtype = TestRunner;
}
