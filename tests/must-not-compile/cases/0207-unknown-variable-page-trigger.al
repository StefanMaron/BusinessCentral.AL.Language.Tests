// @expect AL0118 | The name 'Undeclared' does not exist in the current context.
// A page trigger uses an undeclared variable.
page 50010 "MNC P207"
{
    PageType = Card;
    trigger OnOpenPage()
    begin
        Undeclared := 5;
    end;
}
