// Support enum for TestInterfaceCodeunitStateField.al.
//
/// <summary>
/// Enum that implements "IInterface State Provider". Casting an enum value to the
/// interface (the AL `Enum::... as interface` form) exercises interface dispatch to a
/// codeunit that owns instance state.
/// </summary>
enum 60370 "Interface State Kind" implements "IInterface State Provider"
{
    Extensible = false;

    value(0; "Vendor")
    {
        Implementation = "IInterface State Provider" = "Interface Impl Vendor";
    }
}
