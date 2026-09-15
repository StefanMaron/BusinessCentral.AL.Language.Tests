// Support interface for TestEnumExtImplTests.Codeunit.al.
//
// Deliberately RETURNS a value, unlike "EEM Interface" whose HandleAction returns nothing:
// a procedure with no return cannot say WHICH implementation ran, so a cast that silently
// resolved to the wrong codeunit -- or to a fallback -- would still pass.
interface "EEI Marker"
{
    procedure Marker(): Text;
}
