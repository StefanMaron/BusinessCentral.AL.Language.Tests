// Support enum for TestInterfaceVarCodeunitOut.al — implements "IIvc Backend".

enum 60373 "Ivc Backend Type" implements "IIvc Backend"
{
    Extensible = false;

    value(0; NativeProduce)
    {
        Implementation = "IIvc Backend" = "Ivc Native Impl";
    }
}
