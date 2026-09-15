// Support enum for TestEnumExtImplTests.Codeunit.al.
//
// Carries a DefaultImplementation so the extension's own Implementation can be shown to
// outrank it: without one, "the extension's value dispatched to the extension's codeunit"
// and "the extension's value dispatched to whatever the enum falls back to" are the same
// observation whenever the fallback happens to be right.
enum 60893 "EEI Kind" implements "EEI Marker"
{
    Extensible = true;
    DefaultImplementation = "EEI Marker" = "EEI Default Impl";

    value(0; Base)
    {
        Caption = 'Base';
        Implementation = "EEI Marker" = "EEI Base Impl";
    }
}
