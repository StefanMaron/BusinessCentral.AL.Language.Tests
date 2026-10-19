// @expect AL0175 | Operator '=' cannot be applied to operands of type 'DotNet "System.Text.StringBuilder"' and 'DotNet "System.Text.StringBuilder"'
// @target OnPrem
// @min-al 18
// = between two DotNet class objects (an enum is comparable, a class object is not). AL 16 and 17 report AL0451 for the dotnet block first.
dotnet
{
    assembly("mscorlib")
    {
        type("System.Text.StringBuilder"; DnStringBuilder) { }
    }
}

codeunit 50000 "MNC Codeunit"
{
    procedure Same(): Boolean
    var
        First: DotNet DnStringBuilder;
        Second: DotNet DnStringBuilder;
    begin
        exit(First = Second);
    end;
}
