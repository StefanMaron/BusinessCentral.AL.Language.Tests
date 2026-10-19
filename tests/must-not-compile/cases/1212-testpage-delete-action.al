// @expect AL0132 | 'TestPage MNC AZ Delete List' does not contain a definition for 'Delete'
// A TestPage has no method for the standard Delete action of a page (corpus issue 651 item 12, writer AZ): a test cannot invoke the
// system Delete action of a list row, so the OnBeforeDeleteEvent / OnAfterDeleteEvent subscribers cannot be reached that way.
table 51214 "MNC AZ Delete Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

page 51215 "MNC AZ Delete List"
{
    PageType = List;
    SourceTable = "MNC AZ Delete Row";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
            }
        }
    }
}

codeunit 51216 "MNC AZ Delete Test"
{
    Subtype = Test;

    [Test]
    procedure DeleteRow()
    var
        List: TestPage "MNC AZ Delete List";
    begin
        List.OpenEdit();
        List.Delete().Invoke();
    end;
}
