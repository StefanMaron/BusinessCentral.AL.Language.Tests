// Support enumextension for TestEnumExtImplTests.Codeunit.al: adds a value that declares
// its OWN Implementation, which is the shape under test.
enumextension 60890 "EEI Kind Ext" extends "EEI Kind"
{
    value(10; Extended)
    {
        Caption = 'Extended';
        Implementation = "EEI Marker" = "EEI Ext Impl";
    }

    // Declares NO Implementation of its own, so the cast must reach the BASE enum's
    // DefaultImplementation -- the negative direction of the same claim.
    value(20; "Extended No Impl")
    {
        Caption = 'Extended No Impl';
    }
}
