// @expect AL0582 | 'MNC Impl' does not implement the interface member 'MNC Iface.Do'.
// A codeunit implements an interface and lacks its procedure.
interface "MNC Iface"
{
    procedure Do();
}

codeunit 50000 "MNC Impl" implements "MNC Iface"
{
}
