// Support enum for TestEnumDefaultImplTests.Codeunit.al.
//
// Declares all three implementation slots at once so the fallback ORDER is observable:
// "Has Own" carries its own Implementation, "Falls Back" carries none and must reach
// DefaultImplementation, and an ordinal the enum never declares must reach
// UnknownValueImplementation. Base Application enum 205 "Alt. Cust VAT Reg. Doc." is
// written the second way -- one value, no per-value Implementation, a
// DefaultImplementation for the whole enum.
enum 60309 "EDI Kind" implements "EDI Greeter"
{
    Extensible = true;
    DefaultImplementation = "EDI Greeter" = "EDI Default Impl";
    UnknownValueImplementation = "EDI Greeter" = "EDI Unknown Impl";

    value(0; "Falls Back")
    {
        Caption = 'Falls Back';
    }
    value(1; "Has Own")
    {
        Caption = 'Has Own';
        Implementation = "EDI Greeter" = "EDI Own Impl";
    }
}
